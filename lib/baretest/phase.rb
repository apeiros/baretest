#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Phase
    # The exceptions baretest will not rescue
    # NoMemoryError::   a no-memory error means we don't have enough memory to continue
    # SignalException:: something sent the process a signal to terminate
    # Interrupt::       Ctrl-C was issued, the process should terminate immediatly
    # SystemExit::      the process terminates
    PassthroughExceptions = [::NoMemoryError, ::SignalException, ::Interrupt, ::SystemExit]

    def phase
      raise "Your Phase subclass must override #phase."
    end

    def custom_handler(exception)
# handled_by      = handlers && handlers.find { |handling, handler| exception_class <= handling }
      nil
    end

    def execute(context)
      pending "No code provided" unless @code # no code? that means pending
      begin
        context.instance_eval(&@code)
      rescue *PassthroughExceptions, ::BareTest::Phase::Abortion
        raise # passthrough-exceptions must be passed through
      rescue Exception => exception
        handler = custom_handler(exception)
        if handler then
          handler.call(self, context, exception)
        else
          error(exception)
        end
      end
    end

    def pending(reason)
      raise ::BareTest::Phase::Pending.new(phase, reason)
    end

    def skip(reason)
      raise ::BareTest::Phase::Skip.new(phase, reason)
    end

    def fail(reason)
      raise ::BareTest::Phase::Failure.new(phase, reason)
    end

    def error(exception)
      raise ::BareTest::Phase::Error.new(phase, error)
    end
  end
end
