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
    def status
      @__assertion__[:status]
    end

    # If an exception occured in Assertion#execute, this will contain the
    # Exception object raised.
    def exception
      @__assertion__[:exception]
    end

    # The description of this assertion.
    def description
      @__assertion__[:description]
    end

    # The failure reason.
    def failure_reason
      @__assertion__[:failure_reason]
    end

    # The suite this assertion belongs to
    def suite
      @__assertion__[:suite]
    end

    # The block specifying the assertion
    def block
      @__assertion__[:block]
    end

    # The file this assertion is specified in. Not contructed by Assertion itself.
    def file
      @__assertion__[:file]
    end

    def file=(value)
      @__assertion__[:file] = value
    end

    # The line this assertion is specified on. Not contructed by Assertion itself.
    def line
      @__assertion__[:line]
    end

    def line=(value)
      @__assertion__[:line] = value
    end

    # The lines this assertion spans. Not contructed by Assertion itself.
    def lines
      @__assertion__[:lines]
    end

    def lines=(value)
      @__assertion__[:lines] = value
    end

    # suite::       The suite the Assertion belongs to
    # description:: A descriptive string about what this Assertion tests.
    # &block::      The block definition. Without one, the Assertion will have a
    #               :pending status.
    def initialize(suite, description, &block)
      @__assertion__ = {
        :suite          => suite,
        :description    => (description || "No description given"),
        :status         => nil,
        :failure_reason => nil,
        :exception      => nil,
        :block          => block
      }
    end

    # Cleans the assertion so it is pristine again and can be rerun
    def clean
      # backup @__assertion__
      assertion = @__assertion__

      # remove execute-results from @__assertion__
      assertion.update(
        :status         => nil,
        :failure_reason => nil,
        :exception      => nil
      )

      # remove all instance variables
      instance_variables.each do |ivar|
        remove_instance_variable(ivar)
      end

      # recreate @__assertion__
      @__assertion__ = assertion
    end

    # Run all setups in the order of their nesting (outermost first, innermost last)
    def setup
      @__assertion__[:suite].ancestry_setup.each { |setup| instance_eval(&setup) } if @__assertion__[:suite]
      true
    rescue *PassthroughExceptions
      raise # pass through exceptions must be passed through
    rescue Exception => exception
      @__assertion__[:failure_reason] = "An error occurred during setup"
      @__assertion__[:exception]      = exception
      @__assertion__[:status]         = :error
      false
    end

    # Run all teardowns in the order of their nesting (innermost first, outermost last)
    def teardown
      @__assertion__[:suite].ancestry_teardown.each { |teardown| instance_eval(&teardown) } if @__assertion__[:suite]
    rescue *PassthroughExceptions
      raise # pass through exceptions must be passed through
    rescue Exception => exception
      @__assertion__[:failure_reason] = "An error occurred during setup"
      @__assertion__[:exception]      = exception
      @__assertion__[:status]         = :error
    end

    # Runs the assertion and sets the status and exception
    def execute
      @__assertion__[:exception] = nil
      if @__assertion__[:block] then
        if setup then
          # run the assertion
          begin
            @__assertion__[:status]         = instance_eval(&@__assertion__[:block]) ? :success : :failure
            @__assertion__[:failure_reason] = "Assertion failed" if @__assertion__[:status] == :failure
          rescue *PassthroughExceptions
            raise # pass through exceptions must be passed through
          rescue ::BareTest::Assertion::Failure => failure
            @__assertion__[:status]         = :failure
            @__assertion__[:failure_reason] = failure.message
          rescue Exception => exception
            @__assertion__[:failure_reason] = "An error occurred during execution"
            @__assertion__[:exception]      = exception
            @__assertion__[:status]         = :error
          end
        end
        teardown
      else
        @__assertion__[:status] = :pending
      end
      self
    end

    # Create a pristine copy (as if it had not been run) of this Assertion
    def clean_copy(use_class=nil)
      copy = (use_class || self.class).new(@__assertion__[:suite], @__assertion__[:description], &@__assertion__[:block])
      copy.file  = file
      copy.line  = line
      copy.lines = lines
      copy
    end

    def to_s # :nodoc:
      sprintf "%s %s", self.class, @__assertion__[:description]
    end

    def inspect # :nodoc:
      sprintf "#<%s:%08x suite=%p %p>", self.class, object_id>>1, @__assertion__[:suite], @__assertion__[:description]
    end
  end
end
