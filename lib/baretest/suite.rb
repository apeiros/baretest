#--
# Copyright 2009-2010 by Stefan Rusterholz.
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
    attr_reader   :ancestral_teardown

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

    def finish
      if @parent then
        @depends_on         = @parent.depends_on
        @tags               = @parent.tags
        @ancestral_setup    = @parent.ancestral_setup+@parent.setup
        @ancestral_teardown = @parent.ancestral_teardown+@parent.teardown
      end
      @children.each do |child| child.finish end
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
      @setups.concat(paths.map { |file| SetupRequire.new(file) })
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

    def exercise(description, &code)
      exercise           = Phase::Exercise.new(description, &code)
      @children         << exercise
      @current_exercise  = exercise
      exercise
    end

    def verify(description, &code)
      verification = Phase::Verification.new(description, &code)
      @current_exercise.out_of_order(verfication)
      verification
    end

    def then_verify(description, &code)
      verification = Phase::Verification.new(description, &code)
      @current_exercise.in_order(verfication)
      verification
    end

    # Define a setup block for this suite. The block will be ran before every
    # assertion once, even for nested suites.
#     def setup(*args, &code)
#       if args.empty? && code then # common setup case
#       else
#       if args.first.is_a?(Symbol) then
#         id = args.shift
#         
#     end

    # Define a teardown block for this suite. The block will be ran after every
    # assertion once, even for nested suites.
    def teardown(&code)
      teardown    = Teardown.new(&code)
      @teardowns << teardown
      teardown
    end

    # Returns the number of possible setup variations.
    # See #each_component_variant
    def number_of_setup_variants
      return 0 if @setups.empty?
      @setups.inject(1) { |count, setup| count*setup.length }
    end

    # Yields all possible permutations of setup components.
    def each_setup_variant
      if @setups.empty? then
        yield([])
      else
        maximums = @setups.map { |setup| setup.length }
        number_of_setup_variants.times do |i|
          yield(setup_variant(i, maximums))
        end
      end

      self
    end

    # Return the component variants
    def setup_variant(index, maximums=nil)
      maximums ||= @setups.map { |setup| setup.length }
      process    = maximums.map { |e|
        index, partial = index.divmod(e)
        partial
      }
      @setups.zip(process).map { |setup, partial| setup[partial] }
    end

    def to_s #:nodoc:
      sprintf "%s %s", self.class, @description
    end

    def inspect #:nodoc:
      sprintf "#<%s:%08x %p>", self.class, object_id>>1, @description
    end
  end
end
