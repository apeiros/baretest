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

    def execute(context, test)
      return pending(context, test, "No code provided") unless @code # no code? that means pending
      begin
        context.__phase__ = phase
        context.instance_eval(&@code)
      rescue *PassthroughExceptions
        raise # passthrough-exceptions must be passed through
      rescue ::BareTest::Phase::Abortion => abortion
        BareTest::Status.new(test, abortion.status, context, abortion.message, abortion)
      rescue Exception => exception
        handler = test.custom_handler(exception)
        if handler then
          handler.call(self, context, exception)
        else
          error(context, test, exception)
        end
      else
        nil
      end
    end

    def pending(context, test, reason)
      BareTest::Status.new(test, :pending, context, reason)
    end

    def skip(context, test, reason)
      BareTest::Status.new(test, :skip, context, reason)
    end

    def fail(context, test, reason)
      BareTest::Status.new(test, :failure, context, reason)
    end

    def error(context, test, exception)
      BareTest::Status.new(test, :error, context, "#{exception.class}: #{exception}", exception)
    end
  end
end



require 'baretest/phase/setup'
require 'baretest/phase/exercise'
require 'baretest/phase/verification'
require 'baretest/phase/teardown'
require 'baretest/phase/abortion'
