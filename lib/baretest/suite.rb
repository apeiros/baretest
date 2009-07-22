#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test

  # A Suite is a container for multiple assertions.
  # You can give a suite a description, also a suite can contain
  # setup and teardown blocks that are executed before (setup) and after
  # (teardown) every assertion.
  # Suites can also be nested. Nested suites will inherit setup and teardown.
  class Suite

    # Nested suites
    attr_reader :suites

    # All assertions in this suite
    attr_reader :tests

    # This suites description. Toplevel suites usually don't have a description.
    attr_reader :description

    # This suites direct parent. Nil if toplevel suite.
    attr_reader :parent

    # An Array containing the suite itself (first element), then its direct
    # parent suite, then that suite's parent and so on
    attr_reader :ancestors

    def self.create(description=nil, parent=nil, opts={}, &block)
      Array(opts[:requires]).each { |file| require file } if opts[:requires]
    rescue LoadError
      # A suite is skipped if requirements are not met
      Skipped::Suite.new(description, parent, &block)
    else
      # All suites within Skipped::Suite are Skipped::Suite
      (block ? self : Skipped::Suite).new(description, parent, &block)
    end

    def initialize(description=nil, parent=nil, &block)
      @description = description
      @parent      = parent
      @suites      = []
      @tests       = []
      @setup       = []
      @teardown    = []
      @ancestors   = [self] + (@parent ? @parent.ancestors : [])
      instance_eval(&block) if block
    end

    # Define a nested suite.
    # Nested suites inherit setup & teardown methods.
    # Also if an outer suite is skipped, all inner suites are skipped too.
    # Valid values for opts:
    # requires
    # :   A list of files to require, if one of the requires fails, the suite
    #     will be skipped. Accepts a String or an Array
    def suite(description=nil, opts={}, &block)
      @suites << self.class.create(description, self, opts, &block)
    end

    # All setups in the order of their nesting (outermost first, innermost last)
    def ancestry_setup
      ancestors.map { |suite| suite.setup }.flatten.reverse
    end

    # All teardowns in the order of their nesting (innermost first, outermost last)
    def ancestry_teardown
      ancestors.map { |suite| suite.teardown }.flatten
    end

    # Define a setup block for this suite. The block will be ran before every
    # assertion once, even for nested suites.
    def setup(&block)
      block ? @setup << block : @setup
    end

    # Define a teardown block for this suite. The block will be ran after every
    # assertion once, even for nested suites.
    def teardown(&block)
      block ? @teardown << block : @teardown
    end

    # Define an assertion. The block is supposed to return a trueish value
    # (anything but nil or false).
    # See Assertion for more info.
    def assert(description=nil, &block)
      @tests << Assertion.new(self, description, &block)
    end

    # :nodoc:
    def to_s
      sprintf "%s %s", self.class, @description
    end

    # :nodoc:
    def inspect
      sprintf "#<%s:%08x %p>", self.class, object_id>>1, @description
    end
  end
end
