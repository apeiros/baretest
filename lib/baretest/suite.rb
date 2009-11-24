#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/setup'



module BareTest

  # A Suite is a container for multiple assertions.
  # You can give a suite a description, also a suite can contain
  # setup and teardown blocks that are executed before (setup) and after
  # (teardown) every assertion.
  #
  # Suites can also be nested. Nested suites will inherit setup and teardown.
  class Suite

    # Nested suites, in the order of definition
    attr_reader :suites

    # All assertions in this suite
    attr_reader :assertions

    # All skipped assertions in this suite
    attr_reader :skipped

    # This suites description. Toplevel suites usually don't have a description.
    attr_reader :description

    # This suites direct parent. Nil if toplevel suite.
    attr_reader :parent

    # An Array containing the suite itself (first element), then its direct
    # parent suite, then that suite's parent and so on
    attr_reader :ancestors

    # Create a new suite.
    #
    # The arguments 'description', 'parent' and '&block' are the same as on Suite::new,
    # 'opts' is an additional options hash.
    #
    # Keys the options hash accepts:
    # :requires:: A string or array of strings with requires that have to be done in order to run
    #             this suite. If a require fails, the suite is created as a Skipped::Suite instead.
    #
    def self.create(description=nil, parent=nil, opts={}, &block)
      Array(opts[:requires]).each { |file| require file } if opts[:requires]
    rescue LoadError
      # A suite is skipped if requirements are not met
      Skipped::Suite.new(description, parent, &block)
    else
      # All suites within Skipped::Suite are Skipped::Suite
      (block ? self : Skipped::Suite).new(description, parent, &block)
    end

    # Create a new suite.
    #
    # Arguments:
    # description:: A string with a human readable description of this suite, preferably
    #               less than 60 characters and without newlines
    # parent::      The suite that nests this suite. Ancestry plays a role in execution of setup
    #               and teardown blocks (all ancestors setups and teardowns are executed too).
    # &block::      The given block is instance evaled.
    def initialize(description=nil, parent=nil, &block)
      @description = description
      @parent      = parent
      @suites      = [] # [["description", subsuite, skipped], ["description2", ...], ...] - see Array#assoc
      @assertions  = []
      @skipped     = []
      @setup       = {nil => []}
      @components  = []
      @teardown    = []
      @ancestors   = [self] + (@parent ? @parent.ancestors : [])
      instance_eval(&block) if block
    end

    # Define a nested suite.
    #
    # Nested suites inherit setup & teardown methods.
    # Also if an outer suite is skipped, all inner suites are skipped too.
    #
    # Valid values for opts:
    # :requires:: A list of files to require, if one of the requires fails,
    #               the suite will be skipped. Accepts a String or an Array
    def suite(description=nil, opts={}, &block)
      suite = self.class.create(description, self, opts, &block)
      if append_to = @suites.assoc(description) then
        append_to.last.update(suite)
      else
        @suites << [description, suite]
      end
      suite
    end

    # Performs a recursive merge with the given suite.
    #
    # Used to merge suites with the same description.
    def update(with_suite)
      if ::BareTest::Skipped::Suite === with_suite then
        @skipped.concat(with_suite.skipped)
      else
        @assertions.concat(with_suite.assertions)
        @setup.update(with_suite.setup) do |k,v1,v2| v1+v2 end
        @teardown.concat(with_suite.teardown)
        with_suite.suites.each { |description, suite|
          if append_to = @suites.assoc(description) then
            append_to.last.update(suite)
          else
            @suites << [description, suite]
          end
        }
      end
      self
    end

    # All setups in the order of their definition and nesting (outermost first,
    # innermost last)
    def ancestry_setup
      @parent ? @parent.ancestry_setup.merge(@setup) { |k,v1,v2|
        v1+v2
      } : @setup
    end

    # All setup-components in the order of their definition and nesting
    # (outermost first, innermost last)
    def ancestry_components
      @parent ? @parent.ancestry_components|@components : @components
    end

    # All teardowns in the order of their nesting (innermost first, outermost last)
    def ancestry_teardown
      ancestors.map { |suite| suite.teardown }.flatten
    end

    # Define a setup block for this suite. The block will be ran before every
    # assertion once, even for nested suites.
    def setup(component=nil, multiplexed=nil, &block)
      if block then
        @components << component unless @setup.has_key?(component)
        @setup[component] ||= []
        @setup[component] << ::BareTest::Setup.new(component, multiplexed, block)
      end

      @setup
    end

    # Define a teardown block for this suite. The block will be ran after every
    # assertion once, even for nested suites.
    def teardown(&block)
      block ? @teardown << block : @teardown
    end

    def each_component_variant
      setups     = ancestry_setup
      components = ancestry_components
      base       = setups[nil]

      if components.empty?
        yield(base)
      else
        setup_in_order = setups.values_at(*components)
        maximums       = setup_in_order.map { |i| i.size }
        iterations     = maximums.inject { |r,f| r*f } || 0

        iterations.times do |i|
          process = maximums.map { |e| i,e=i.divmod(e); e }
          yield base+setup_in_order.zip(process).map { |variants, current|
            variants[current]
          }
        end
      end

      self
    end

    # Define an assertion. The block is supposed to return a trueish value
    # (anything but nil or false).
    #
    # See Assertion for more info.
    def assert(description=nil, &block)
      assertion = Assertion.new(self, description, &block)
      if match = caller.first.match(/^(.*):(\d+)(?::.+)?$/) then
        file, line = match.captures
        file = File.expand_path(file)
        if File.exist?(file) then
          assertion.file = file
          assertion.line = line.to_i
        end
      end
      @assertions << assertion
    end

    def to_s #:nodoc:
      sprintf "%s %s", self.class, @description
    end

    def inspect #:nodoc:
      sprintf "#<%s:%08x %p>", self.class, object_id>>1, @description
    end
  end
end



require 'baretest/skipped/suite' # TODO: determine why this require is on the bottom and document it.
