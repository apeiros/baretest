#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/assertion'
require 'baretest/commandline'
require 'baretest/formatter'
require 'baretest/invalidselectors'
require 'baretest/irb_mode'
require 'baretest/run'
require 'baretest/suite'
require 'baretest/version'
require 'ruby/kernel'
# See bottom for more requires



module BareTest
  # A lookup table to test which of two states is more important
  # (MoreImportantStatus[[a,b]] # => a or b)
  MoreImportantStatus = {}

  # All states in the order of relevance, more relevant states first
  StatusOrder         = :error,
                        :failure,
                        :pending,
                        :manually_skipped,
                        :dependency_missing,
                        :library_missing,
                        :component_missing,
                        :ignored,
                        :success

  StatusOrder.combination(2) do |x,y|
    more_important = StatusOrder.index(x) < StatusOrder.index(y) ? x : y
    MoreImportantStatus[[x,y]] = more_important
    MoreImportantStatus[[y,x]] = more_important
  end
  StatusOrder.each do |status|
    MoreImportantStatus[[status,status]] = status
    MoreImportantStatus[[nil,status]]    = status
    MoreImportantStatus[[status,nil]]    = status
  end

  # The standard glob used by baretest to load test files
  # :nodoc:
  DefaultInitialPositiveGlob = 'test/{suite,unit,isolation,integration,system}/**/*.rb'

  # Selectors that are valid to be passed into process_selectors
  # :nodoc:
  ValidStateSelectors = [:new, :success, :failure, :error, :skipped, :pending]

  class << self
    # A hash of components - available via BareTest::use(name) and
    # Suite#suite :use => name
    attr_reader :components

    # A hash of formatters (require-string => module) to be used with Test::Run.
    attr_reader :format

    # For mock integration and others, append modules that should extend the Test::Run instance.
    attr_reader :extender

    # The toplevel suite. That's the one run_if_mainfile and define add suites
    # and assertions to.
    attr_reader :toplevel_suite

    # The full path to this file
    # Needed to test baretest itself using baretest
    attr_reader :required_file # :nodoc:
  end

  # Loads all files in a test directory in order to load the suites and
  # assertions. Used by the 'baretest' executable and the standard rake task.
  #
  # Options:
  # :verbose::    Will print information about the load process (default: false)
  # :setup_path:: The path to the setup file, the first loaded file (default: 'test/setup.rb')
  # :chdir::      The directory this routine chdirs before loading, will jump back to the original
  #               directory after loading (default: '.')
  def self.load_standard_test_files(opts={})
    verbose    = opts.delete(:verbose)
    setup_path = opts.delete(:setup_path) || 'test/setup.rb'
    chdir      = opts.delete(:chdir) || '.'
    files      = opts.delete(:files)
    files      = [DefaultInitialPositiveGlob] if (files.nil? || files.empty?)
    Dir.chdir(chdir) do
      load(setup_path) if File.exist?(setup_path)
      files.each do |glob|
        glob = "#{glob}/**/*.rb" if File.directory?(glob)
        Dir.glob(glob) { |path|
          helper_path = path.sub(%r{^test/(suite|unit|integration|system)/}, 'test/helper/\1/')
          exists = (helper_path != path && File.exist?(helper_path))
          puts(exists ? "Loading helper file #{helper_path}" : "No helper file #{helper_path} to load") if verbose
          load(helper_path) if exists
          puts "Loading test file #{path}" if verbose
          load(path)
        }
      end
    end
  end

  # Determine which of the named states is the most important one (see
  # StatusOrder)
  def self.most_important_status(states)
    (StatusOrder & states).first # requires Array#& to be stable (keep order of first operand)
  end

  def self.process_selectors(selectors, base_directory=".", default_initial_positive_glob=nil)
    files           = []
    include_tags    = []
    exclude_tags    = []
    include_states  = []
    exclude_states  = []

    default_initial_positive_glob ||= DefaultInitialPositiveGlob
    Dir.chdir(base_directory) do
      selectors.each do |selector|
        case selector
          when /\A-%(.*)/   then exclude_states << $1.to_sym
          when /\A-:(.*)/   then exclude_tags << $1.to_sym
          when /\A\+?%(.*)/ then include_states << $1.to_sym
          when /\A\+?:(.*)/ then include_tags << $1.to_sym
          when /\A-(.*)/    then
            files  = Dir[default_initial_positive_glob] if files.empty? && default_initial_positive_glob
            glob   = File.directory?($1) ? "#{$1}/**/*.rb" : $1
            files -= Dir[glob]
          when /\A\+?(.*)/  then
            glob   = File.directory?(selector) ? "#{selector}/**/*.rb" : selector
            files |= Dir[glob]
          else
            raise "Should never reach else - selector: #{selector.inspect}"
        end
      end
      files  = Dir[default_initial_positive_glob] if files.empty? && default_initial_positive_glob
      files.map! do |path| File.expand_path(path) end
    end

    invalid_states = (include_states|exclude_states)-ValidStateSelectors
    raise InvalidSelectors.new(invalid_states) unless invalid_states.empty?

    return {
      :files          => files,
      :include_tags   => include_tags,
      :exclude_tags   => exclude_tags,
      :include_states => include_states.empty? ? nil : include_states,
      :exclude_states => exclude_states.empty? ? nil : exclude_states
    }
  end

  # Initializes BareTest, is automatically called
  #
  # Needed for bootstrapped selftest
  def self.init # :nodoc:
    @components     = {}
    @format         = {}
    @extender       = []
    @toplevel_suite = BareTest::Suite.new
    @required_file  = ["", *$LOAD_PATH].map { |path|
      File.expand_path(File.join(path, __FILE__))
    }.find { |full| File.exist?(full) }
  end
  init

  def self.component(name)
    component = @components[name]
    begin
      require "baretest/use/#{name}"
    rescue LoadError
    else
      component = @components[name]
    end
    component
  end

  # If no description was given, it adds the contained assertions and suites to the toplevel suite,
  # if a description was given, a suite with the given description is created, added to the toplevel
  # suite, and all the contained assertions and suites are added to the created suite.
  def self.suite(description=nil, opts={}, &block)
    if description then
      @toplevel_suite.suite(description, opts, &block)
    elsif opts && !opts.empty?
      raise ArgumentError, "Suites with options must have names"
    else
      @toplevel_suite.instance_eval(&block)
    end
  end

  def self.new_component(name, &block)
    name = name.to_sym
    raise ArgumentError, "Component named #{name.inspect} already exists" if @components.has_key?(name)
    @components[name] = block
  end

  def self.use(component)
    @toplevel_suite.use(component)
  end
end



# At bottom due to dependencies
require 'baretest/assertion/support' # Needs Test.extender to be defined
