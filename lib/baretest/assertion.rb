#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/assertion/context'
require 'baretest/assertion/failure'
require 'baretest/assertion/skip'
require 'baretest/status'



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

    # The description of this assertion.
    attr_reader :description

    # The suite this assertion belongs to
    attr_reader :suite

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
    def initialize(suite, description, opt=nil, &block)
      @suite       = suite
      @description = (description || "No description given")
      @block       = block
      @skipped     = false
      if opt then
        skip_reason = opt[:skip]
        skip(skip_reason == true ? "Tagged as skipped" : skip_reason) if skip_reason
      end
    end

    # An ID, usable for persistence
    def id
      @id ||= [
        @description,
        *(@suite && @suite.ancestors.map { |suite| suite.description })
      ].compact.join("\f")
    end

    def skipped?
      !!@skipped
    end

    def skip(reason=nil)
      @skipped ||= []
      @skipped  |= reason ? Array(reason) : ['Manually skipped']
    end

    def interpolated_description(substitutes)
      if substitutes.empty? then
        @description
      else
        @description.gsub(/:(?:#{substitutes.keys.join('|')})\b/) { |m|
          substitutes[m[1..-1].to_sym]
        }
      end
    end

    # Returns a Status
    # Executes with_setup, then the assertions defining block, and in the end
    # and_teardown. Usually with_setup and and_teardown are supplied by the
    # containing suite.
    def execute(with_setup=nil, and_teardown=nil)
      if @skipped then
        status = Status.new(self, :manually_skipped)
      elsif !@block
        status = Status.new(self, :pending)
      else
        context  = ::BareTest::Assertion::Context.new(self)
        status   = execute_phase(:setup, context, with_setup) if with_setup
        status   = execute_phase(:exercise, context, @block) unless status
        status   = execute_phase(:teardown, context, and_teardown) unless (status || !and_teardown)
        status ||= Status.new(self, :success, context)
      end

      status
    end

    # A phase can result in either success, skip, failure or error
    # Execute_phase will simply return nil upon success, all other cases
    # will generate a full Status instance.
    # This is for practical reasons - it means you can go through several
    # phases, looking for the first non-nil one.
    def execute_phase(name, context, code)
      status         = nil
      skip_reason    = nil
      failure_reason = nil
      exception      = nil

      begin
        if code.is_a?(Array) then
          code.each do |block| context.instance_eval(&block) end
        else
          unless context.instance_eval(&code)
            failure_reason = "Assertion failed" 
            status         = :failure
          end
        end
      rescue *PassthroughExceptions
        raise # passthrough-exceptions must be passed through
      rescue ::BareTest::Assertion::Failure => failure
        status         = :failure
        failure_reason = failure.message
      rescue ::BareTest::Assertion::Skip => skip
        status         = :manually_skipped
        skip_reason    = skip.message
      rescue Exception => exception
        status         = :error
        failure_reason = "An error occurred during #{name}: #{exception}"
        exception      = exception
      end

      status && Status.new(self, status, context, skip_reason, failure_reason, exception)
    end

    def to_s # :nodoc:
      sprintf "%s %s", self.class, @description
    end

    def inspect # :nodoc:
      sprintf "#<%s:%08x suite=%p %p>", self.class, object_id>>1, @suite, @description
    end
  end
end
