#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/status'



module BareTest
  class Phase
    # The exceptions baretest will not rescue
    # NoMemoryError::   a no-memory error means we don't have enough memory to continue
    # SignalException:: something sent the process a signal to terminate
    # Interrupt::       Ctrl-C was issued, the process should terminate immediatly
    # SystemExit::      the process terminates
    PassthroughExceptions = [::NoMemoryError, ::SignalException, ::Interrupt, ::SystemExit]

    def initialize(&code)
      @code = code
    end

    def phase
      raise "Your Phase subclass must override #phase."
    end

    def execute(test)
      return pending(test, "No code provided") unless @code # no code? that means pending

      context = test.context
      begin
        context.__phase__ = phase
        context.instance_eval(&@code)
      rescue *PassthroughExceptions
        raise # passthrough-exceptions must be passed through
      rescue ::BareTest::Phase::Abortion => abortion
        test.status = BareTest::Status.new(test, abortion.status, context, abortion.message, abortion)
      rescue Exception => exception
        handler = test.custom_handler(exception)
        if handler then
          handler.call(self, test, exception)
        else
          error(test, exception)
        end
      else
        nil
      end
    end

    def pending(test, reason)
      test.status = BareTest::Status.new(test, :pending, phase, reason)
    end

    def skip(test, reason)
      test.status = BareTest::Status.new(test, :skip, phase, reason)
    end

    def fail(test, reason)
      test.status = BareTest::Status.new(test, :failure, phase, reason)
    end

    def error(test, exception)
      test.status = BareTest::Status.new(test, :error, phase, "#{exception.class}: #{exception}", exception)
    end

    def status(test, code, reason=nil, exception=nil)
      test.status = BareTest::Status.new(test, code, phase, reason, exception)
    end
  end
end



require 'baretest/phase/setup'
require 'baretest/phase/exercise'
require 'baretest/phase/verification'
require 'baretest/phase/teardown'
require 'baretest/phase/abortion'
