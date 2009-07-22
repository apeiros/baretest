#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/assertion/failure'



module BareTest

  # Defines an assertion
  # An assertion belongs to a suite and consists of a description and a block.
  # The verify the assertion, the suite's (and its ancestors) setup blocks are
  # executed, then the assertions block is executed and after that, the suite's
  # (and ancestors) teardown blocks are invoked.
  #
  # An assertion has 5 possible states, see Assertion#status for a list of them.
  #
  # There are various helper methods in lib/test/support.rb which help you
  # defining nicer diagnostics or just easier ways to test common scenarios.
  # The following are test helpers:
  # * Kernel#raises(exception_class=StandardError)
  # * Kernel#within_delta(a, b, delta)
  # * Kernel#equal_unordered(a,b)
  # * Enumerable#equal_unordered(other)
  class Assertion

    # An assertion has 5 possible states:
    # :success
    # :    The assertion passed. This means the block returned a trueish value.
    # :failure
    # :    The assertion failed. This means the block returned a falsish value.
    #      Alternatively it raised a Test::Failure (NOT YET IMPLEMENTED).
    #      The latter has the advantage that it can provide nicer diagnostics.
    # :pending
    # :    No block given to the assertion to be run
    # :skipped
    # :    If one of the parent suites is missing a dependency, its assertions
    #      will be skipped
    # :error
    # :    The assertion errored out. This means the block raised an exception
    attr_reader :status

    # If an exception occured in Assertion#execute, this will contain the
    # Exception object raised.
    attr_reader :exception

    # The description of this assertion.
    attr_reader :description

    # The failure reason.
    attr_reader :failure_reason

    # The suite this assertion belongs to
    attr_reader :suite

    # The block specifying the assertion
    attr_reader :block

    # suite
    # :   The suite the Assertion belongs to
    # description
    # :   A descriptive string about what this Assertion tests.
    # &block
    # :   The block definition. Without one, the Assertion will have a :pending
    #     status.
    def initialize(suite, description, &block)
      @suite          = suite
      @status         = nil
      @failure_reason = nil
      @exception      = nil
      @description    = description || "No description given"
      @block          = block
    end

    # Run all setups in the order of their nesting (outermost first, innermost last)
    def setup
      @suite.ancestry_setup.each { |setup| instance_eval(&setup) } if @suite
    end

    # Run all teardowns in the order of their nesting (innermost first, outermost last)
    def teardown
      @suite.ancestry_teardown.each { |setup| instance_eval(&setup) } if @suite
    end

    # Runs the assertion and sets the status and exception
    def execute
      @exception = nil
      if @block then
        setup
        # run the assertion
        begin
          @status = instance_eval(&@block) ? :success : :failure
        rescue ::BareTest::Assertion::Failure => failure
          @status         = :failure
          @failure_reason = failure
        rescue => exception
          @failure_reason = "An error occurred"
          @exception      = exception
          @status         = :error
        end
        teardown
      else
        @status = :pending
      end
      self
    end

    def clean_copy(use_class=nil)
      (use_class || self.class).new(@suite, @description, &@block)
    end

    # :nodoc:
    def to_s
      sprintf "%s %s", self.class, @description
    end

    # :nodoc:
    def inspect
      sprintf "#<%s:%08x @suite=%p %p>", self.class, object_id>>1, @suite, @description
    end
  end
end
