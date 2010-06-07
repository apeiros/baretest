#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase'
require 'baretest/unit'
require 'baretest/setupconstructor'



module BareTest

  # A Suite is a container for multiple assertions.
  # You can give a suite a description, also a suite can contain
  # setup and teardown blocks that are executed before (setup) and after
  # (teardown) every assertion.
  #
  # Suites can also be nested. Nested suites will inherit setup and teardown.
  class Suite

    # This suites identifier, usable for persistence. Determined by its
    # description and parent id
    attr_reader   :id

    # Whether this suite has been manually skipped (either via
    # Suite.new(..., :skip => reason) or via Suite#skip)
    attr_reader   :skipped

    # This suites description. Toplevel suites usually don't have a description.
    attr_reader   :description

    # This suites direct parent. Nil if toplevel suite.
    attr_reader   :parent
    attr_reader   :children

    # An Array containing the suite itself (first element), then its direct
    # parent suite, then that suite's parent and so on
    attr_reader   :ancestors

    # All things this suite depends on, see Suite::new for more information
    attr_reader   :depends_on

    # All things this suite provides, see Suite::new for more information
    attr_reader   :provides

    # All things this suite is tagged with, see Suite::new for more information
    attr_reader   :tags

    attr_reader   :nesting_level

    attr_reader   :ancestral_setup
    attr_reader   :ancestral_maximums
    attr_reader   :ancestral_variants
    attr_reader   :ancestral_setup_counts
    attr_reader   :ancestral_teardown
    attr_reader   :ancestral_teardown_counts

    # A list of valid options Suite::new accepts
    ValidOptions = [:skip, :requires, :use, :provides, :depends_on, :tags]

    # Create a new suite.
    #
    # Arguments:
    # description:: A string with a human readable description of this suite,
    #               preferably less than 60 characters and without newlines
    # parent::      The suite that nests this suite. Ancestry plays a role in
    #               execution of setup and teardown blocks (all ancestors setups
    #               and teardowns are executed too).
    # opts::        An additional options hash.
    #
    # Keys the options hash accepts:
    # :skip::       Skips the suite if true or a String is passed. If a String
    #               is passed, it is used as the reason.
    # :requires::   A string or array of strings with requires that have to be
    #               done in order to run this suite. If a require fails, the
    #               assertions will all be skipped with reason "Missing
    #               dependency".
    # :use::        A symbol or array of symbols with components this suite
    #               should load prior to running.
    # :provides::   A symbol or array of symbols with dependencies this suite
    #               resolves, see 'depends_on'.
    # :depends_on:: A symbol or array of symbols with dependencies of this
    #               suite, see 'provides'.
    # :tags::       A symbol or array of symbols, useful to run only suites
    #               having/not having specific tags
    #
    # &block::      The given block is instance evaled and can contain further
    #               definition of this assertion. See Suite#suite and
    #               Suite#assert.
    def initialize(description=nil, parent=nil, opts=nil, &block)
      @id                 = parent ? "#{parent.id}\f#{description}" : description.to_s # to_s because of nil descriptions
      @description        = description
      @parent             = parent
      @ancestors          = parent ? [self, *@parent.ancestors] : [self]
      @nesting_level      = @ancestors.length-1
      @children           = []
      @setups             = []
      @teardowns          = []
      @ancestral_setup    = []
      @ancestral_teardown = []
      @by_name            = {} # named setups use Symbols, Suites and Assertions use Strings
      @setup_variants     = 0

      @skipped            = false
      @depends_on         = []
      @tags               = []
      @provides           = []
      @reason             = [] # skip reason
      @options            = nil

      merge_options(opts) if opts
      instance_eval(&block) if block
    end

    # Add options of an options hash to this suite
    def merge_options(opts)
      warn "Multiple option sources" if @options # FIXME: improve warning message
      @options = true

      raise ArgumentError, "Invalid option(s): #{(opts.keys - ValidOptions).inspect}" unless (opts.keys - ValidOptions).empty?
      skip, requires, use, provides, depends_on, tags = opts.values_at(*ValidOptions)

      skip(skip == true ? nil : skip) if skip
      use(*use) if use
      requires(*requires) if requires

      @depends_on |= Array(depends_on) if depends_on
      @provides   |= Array(provides) if provides
      @tags       |= Array(tags) if tags
    end

    def finish_loading
      blocks                     = @setups.size
      @ancestral_setup           = @setups
      @ancestral_maximums        = @setups.map { |setup| setup.length }
      @ancestral_variants        = @ancestral_maximums.inject { |a,b| a*b }
      @ancestral_setup_counts    = [@setups.length]
      @ancestral_teardown        = @teardowns
      @ancestral_teardown_counts = [@teardowns.length]

      if @parent then
        @depends_on                = @parent.depends_on
        @tags                      = @tags | @parent.tags
        @ancestral_setup           = @parent.ancestral_setup+@ancestral_setup
        @ancestral_maximums        = @parent.ancestral_maximums+@ancestral_maximums
        @ancestral_variants        = @parent.ancestral_variants ? @parent.ancestral_variants*(@ancestral_variants||1) : @ancestral_variants
        @ancestral_setup_counts    = @parent.ancestral_setup_counts+[@ancestral_setup_counts.last+@parent.ancestral_setup_counts.last]
        @ancestral_teardown        = @parent.ancestral_teardown+@ancestral_teardown
        @ancestral_teardown_counts = @parent.ancestral_teardown_counts+[@ancestral_teardown_counts.last+@parent.ancestral_teardown_counts.last]
      end

      @children.each do |child| child.finish_loading end
    end

    def all_units
      units = []
      @children.each do |child|
        case child
          when Suite then units.concat(child.all_units)
          when Unit then  units << child
        end
      end
      units
    end

    def each_setup_variation
      unless @ancestral_variants then
        yield([])
      else
        @ancestral_variants.times do |variant|
          setups_variant = []
          @ancestral_setup.zip(@ancestral_maximums) do |setup, maximum|
            variant, partial = variant.divmod(maximum)
            setups_variant << setup[partial]
          end
          yield(setups_variant)
        end
      end
    end

    # Instruct this suite to use the given components.
    # The suite is skipped if a component is not available.
    def use(*components)
      components.each do |name|
        component = BareTest.component(name)
        if component then
          instance_eval(&component)
        else
          skip("Missing component: #{name.inspect}")
        end
      end
    end

    # Instruct this suite to require the given files.
    # The suite is skipped if a file can't be loaded.
    def requires(*paths)
      @setups.concat(paths.map { |file| BareTest::Phase::SetupRequire.new(file) })
    end

    # Returns whether this Suite has all the passed tags
    # Must be an Array of Symbols.
    def tagged?(tags)
      (tags-@tags).empty?
    end

    # Marks this Suite as manually skipped.
    def skip(reason=nil)
      reason    = [reason || 'Manually skipped'] unless reason.kind_of?(Array)
      @skipped  = true
      @reason  |= reason
      true
    end

    # Returns whether this Suite has been marked as manually skipped.
    def skipped?
      @skipped
    end

    # The failure/error/skipping/pending reason.
    # Returns nil if there's no reason, a string otherwise
    # Options:
    # :separator::    String used to separate multiple reasons
    # :indent::       A String, the indentation to use. Prefixes every line.
    # :first_indent:: A String, used to indent the first line only (replaces indent).
    def reason(opt=nil)
      if opt then
        invalid_keys = opt.keys-[:separator, :indent, :first_indent]
        raise ArgumentError, "Unknown options: #{invalid_keys.inspect}" unless invalid_keys.empty?
        separator, indent, first_indent = *opt.values_at(:separator, :indent, :first_indent)
        reason = @reason
        reason = Array(default) if reason.empty? && default
        return nil if reason.empty?
        reason = reason.join(separator || "\n")
        reason = reason.gsub(/^/, indent) if indent
        reason = reason.gsub(/^#{Regexp.escape(indent)}/, first_indent) if first_indent
        reason
      else
        @reason.empty? ? nil : @reason.join("\n")
      end
    end

    # Define a nested suite.
    #
    # Nested suites inherit setup & teardown methods.
    # Also if an outer suite is skipped, all inner suites are skipped too.
    #
    # See Suite::new - all arguments are passed to it verbatim, and self is
    # added as parent.
    def suite(description=nil, opts=nil, &block)
      existing_suite = @by_name[description]
      if existing_suite then
        existing_suite.merge_options(opts) if opts
        existing_suite.instance_eval(&block) if block
        suite = existing_suite
      else
        suite = self.class.new(description, self, opts, &block)
        @by_name[description] = suite
        @children            << suite
      end
      suite
    end

    def exercise(description, options=nil, &code)
      exercise       = Phase::Exercise.new(description, options, &code)
      exercise.user_file, exercise.user_line = extract_file_and_line(caller.first)
      unit           = Unit.new(self, exercise)
      @children     << unit
      @current_unit  = unit
      exercise
    end

    def verify(description, options=nil, &code)
      raise "You must define an exercise before defining verifications" unless @current_unit
      verification = Phase::Verification.new(description, options, &code)
      verification.user_file, verification.user_line = extract_file_and_line(caller.first)
      @current_unit.out_of_order(verification)
      verification
    end

    def then_verify(description, &code)
      raise "You must define an exercise before defining verifications" unless @current_unit
      verification = Phase::Verification.new(description, &code)
      verification.user_file, verification.user_line = extract_file_and_line(caller.first)
      @current_unit.in_order(verification)
      verification
    end

    # Define a setup block for this suite. The block will be ran before every
    # assertion once, even for nested suites.
    def setup(id=nil, variables=nil, &code)
      #p :setup_caller => caller
      existing = id && @by_name[id]
      if code then
        if existing then
          existing.add_variant(variables, &code)
        elsif id then
          add_setup Phase::SetupBlockVariants.new(id, variables, &code)
        else
          add_setup Phase::Setup.new(id, &code)
        end
      else
        SetupConstructor.new(self, id, existing)
      end
    end

    def add_setup(setup)
      @by_name[setup.id]  = setup if setup.id
      @setups << setup
      setup
    end

    # Define a teardown block for this suite. The block will be ran after every
    # assertion once, even for nested suites.
    def teardown(&code)
      teardown    = Phase::Teardown.new(&code)
      teardown.user_file, teardown.user_line = extract_file_and_line(caller.first)
      @teardowns << teardown
      teardown
    end

    def extract_file_and_line(caller_line)
      matched = caller_line.match(/^(.*):(\d+)/)
      if matched then
        file, line = matched.captures
        [File.expand_path(file), line.to_i]
      else
        [nil, nil]
      end
    end

    def to_s #:nodoc:
      sprintf "%s %s", self.class, @description
    end

    def inspect #:nodoc:
      sprintf "#<%s:%08x %p>", self.class, object_id>>1, @description
    end
  end
end
