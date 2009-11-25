#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/assertion/context'
require 'baretest/assertion/failure'
require 'baretest/assertion/skip'



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

    # The failure/error/skipping/pending reason.
    attr_reader :reason

    # The suite this assertion belongs to
    attr_reader :suite

    # The Context-instance the assertions setup, assert and teardown are run
    attr_reader :context

    # The Setup instances whose #block is to be executed before this assertion
    # is ran
    attr_accessor :setups

    # The block specifying the assertion
    attr_reader :block

    # The file this assertion is specified in. Not contructed by Assertion itself.
    attr_accessor :code

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
      @description    = (description || "No description given")
      @setups         = nil
      @block          = block
      reset
    end

    def reset
      @status    = nil
      @reason    = nil
      @exception = nil
      @context   = ::BareTest::Assertion::Context.new(self)
    end

    def interpolated_description
      setups = @setups ? @setups.select { |s| s.component } : []
      if setups.empty? then
        @description
      else
        substitutes = {}
        setups.each do |setup| substitutes[setup.component] = setup.substitute end
        @description.gsub(/:(?:#{substitutes.keys.join('|')})\b/) { |m|
          substitutes[m[1..-1].to_sym]
        }
      end
    end

    # Run all setups in the order of their nesting (outermost first, innermost last)
    def setup
      @setups  ||= @suite ? @suite.first_component_variant : []
      @setups.each do |setup| @context.instance_exec(setup.value, &setup.block) end
      true
    rescue *PassthroughExceptions
      raise # pass through exceptions must be passed through
    rescue Exception => exception
      @reason    = "An error occurred during setup"
      @exception = exception
      @status    = :error
      false
    end

    # Run all teardowns in the order of their nesting (innermost first, outermost last)
    def teardown
      @suite.ancestry_teardown.each do |teardown|
        @context.instance_eval(&teardown)
      end if @suite
    rescue *PassthroughExceptions
      raise # pass through exceptions must be passed through
    rescue Exception => exception
      @reason    = "An error occurred during setup"
      @exception = exception
      @status    = :error
    end

    # Runs the assertion and sets the status and exception
    def execute(setups=nil)
      @setups    = setups if setups
      @exception = nil
      if @block then
        if setup() then
          # run the assertion
          begin
            @status = @context.instance_eval(&@block) ? :success : :failure
            @reason = "Assertion failed" if @status == :failure
          rescue *PassthroughExceptions
            raise # pass through exceptions must be passed through
          rescue ::BareTest::Assertion::Failure => failure
            @status = :failure
            @reason = failure.message
          rescue ::BareTest::Assertion::Skip => skip
            @status = :skipped
            @reason = skip.message
          rescue Exception => exception
            @reason    = "An error occurred during execution"
            @exception = exception
            @status    = :error
          end
        end
        teardown
      else
        @status = :pending
      end
      self
    end

    def to_s # :nodoc:
      sprintf "%s %s", self.class, @description
    end

    def inspect # :nodoc:
      sprintf "#<%s:%08x suite=%p %p>", self.class, object_id>>1, @suite, @description
    end
  end
end
