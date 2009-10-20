#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/assertion/failure'



module BareTest

  # Defines an assertion
  # An assertion belongs to a suite and consists of a description and a block.
  # To verify the assertion, the suite's (and its ancestors) setup blocks are
  # executed, then the assertions block is executed and after that, the suite's
  # (and ancestors) teardown blocks are invoked.
  #
  # An assertion has 5 possible states, see Assertion#status for a list of them.
  #
  # There are various helper methods in BareTest::Assertion::Support which help you
  # defining nicer diagnostics or just easier ways to test common scenarios.
  # The following are test helpers:
  # * Kernel#raises(exception_class=StandardError)
  # * Kernel#within_delta(a, b, delta)
  # * Kernel#equal_unordered(a,b)
  # * Enumerable#equal_unordered(other)
  class Assertion

    # The exceptions baretest will not rescue (NoMemoryError, SignalException, Interrupt
    # and SystemExit)
    PassthroughExceptions = [NoMemoryError, SignalException, Interrupt, SystemExit]

    # An assertion has 5 possible states:
    # :success:: The assertion passed. This means the block returned a trueish value.
    # :failure:: The assertion failed. This means the block returned a falsish value.
    #            Alternatively it raised a Test::Failure (NOT YET IMPLEMENTED).
    #            The latter has the advantage that it can provide nicer diagnostics.
    # :pending:: No block given to the assertion to be run
    # :skipped:: If one of the parent suites is missing a dependency, its assertions
    #            will be skipped
    # :error::   The assertion errored out. This means the block raised an exception
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

    # The file this assertion is specified in. Not contructed by Assertion itself.
    attr_accessor :file

    # The line this assertion is specified on. Not contructed by Assertion itself.
    attr_accessor :line

    # The lines this assertion spans. Not contructed by Assertion itself.
    attr_accessor :lines

    # suite::       The suite the Assertion belongs to
    # description:: A descriptive string about what this Assertion tests.
    # &block::      The block definition. Without one, the Assertion will have a
    #               :pending status.
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
      true
    rescue *PassthroughExceptions
      raise # pass through exceptions must be passed through
    rescue Exception => exception
      @failure_reason = "An error occurred during setup"
      @exception      = exception
      @status         = :error
      false
    end

    # Run all teardowns in the order of their nesting (innermost first, outermost last)
    def teardown
      @suite.ancestry_teardown.each { |setup| instance_eval(&setup) } if @suite
    rescue *PassthroughExceptions
      raise # pass through exceptions must be passed through
    rescue Exception => exception
      @failure_reason = "An error occurred during setup"
      @exception      = exception
      @status         = :error
    end

    # Runs the assertion and sets the status and exception
    def execute
      @exception = nil
      if @block then
        if setup then
          # run the assertion
          begin
            @status         = instance_eval(&@block) ? :success : :failure
            @failure_reason = "Assertion failed" if @status == :failure
          rescue *PassthroughExceptions
            raise # pass through exceptions must be passed through
          rescue ::BareTest::Assertion::Failure => failure
            @status         = :failure
            @failure_reason = failure
          rescue Exception => exception
            @failure_reason = "An error occurred during execution"
            @exception      = exception
            @status         = :error
          end
        end
        teardown
      else
        @status = :pending
      end
      self
    end

    # Create a pristine copy (as if it had not been run) of this Assertion
    def clean_copy(use_class=nil)
      copy = (use_class || self.class).new(@suite, @description, &@block)
      copy.file  = file
      copy.line  = line
      copy.lines = lines
      copy
    end

    def to_s # :nodoc:
      sprintf "%s %s", self.class, @description
    end

    def inspect # :nodoc:
      sprintf "#<%s:%08x @suite=%p %p>", self.class, object_id>>1, @suite, @description
    end
  end
end
