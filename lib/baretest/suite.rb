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

    attr_reader   :setup
    attr_reader   :ancestral_setup
    attr_reader   :teardown
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
      @children           = []
      @setup              = []
      @teardown           = []
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
      paths.each do |file| setup SetupRequire.new(file) end
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
      if component.nil? && block then
        @setup[nil] << ::BareTest::Setup.new(nil, nil, nil, block)
      elsif block then
        @components << component unless @setup.has_key?(component)
        @setup[component] ||= []

        case multiplexed
          when nil, String
            @setup[component] << ::BareTest::Setup.new(component, multiplexed, nil, block)
          when Array
            multiplexed.each do |substitute|
              @setup[component] << BareTest::Setup.new(component, substitute.to_s, substitute, block)
            end
          when Hash
            multiplexed.each do |substitute, value|
              @setup[component] << BareTest::Setup.new(component, substitute, value, block)
            end
          else
            raise TypeError, "multiplexed must be an instance of NilClass, String, Array or Hash, but #{multiplexed.class} given."
        end
      elsif component || multiplexed
        raise ArgumentError, "With component or multiplexed given, a block must be provided too."
      end

      @setup
    end

    # Define a teardown block for this suite. The block will be ran after every
    # assertion once, even for nested suites.
    def teardown(&block)
      block ? @teardown << block : @teardown
    end

    # Returns the number of possible setup variations.
    # See #each_component_variant
    def component_variant_count
      ancestry_setup.values_at(*ancestry_components).inject(1) { |r,f| r*f.size }
    end

    # Yields all possible permutations of setup components.
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

    # Return only the first of all possible setup variation permutations.
    def first_component_variant
      setups, *comps = ancestry_setup.values_at(nil, *ancestry_components)
      setups = setups+comps.map { |comp| comp.first }
      yield(setups) if block_given?

      setups
    end

    # Define an assertion. The block is supposed to return a trueish value
    # (anything but nil or false).
    #
    # See Assertion for more info.
    def assert(description=nil, opts=nil, &block)
      assertion = Assertion.new(self, description, opts, &block)
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
    alias guard assert # TODO: This is temporary, guards should become first class citizens

    def to_s #:nodoc:
      sprintf "%s %s", self.class, @description
    end

    def inspect #:nodoc:
      sprintf "#<%s:%08x %p>", self.class, object_id>>1, @description
    end

  protected
    # All attributes that are required when merging two suites
    def merge_attributes
      return @assertions,
             @setup,
             @teardown,
             @provides,
             @depends_on,
             @skipped,
             @reason,
             @suites
    end
  end
end
