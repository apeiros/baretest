#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase'



module BareTest
  class Phase
    class Verification < Phase
      attr_reader :description

      def initialize(description, options=nil, &code)
        if options then
          code = proc {
            raise BareTest::Phase::Pending.new(:verification, "Tagged as pending (#{options[:pending]})")
          } if options[:pending]
        end
        @description = description
        @code        = code
      end

      def phase
        :verification
      end

      def execute(test)
        return pending(test, "No code provided") unless @code # no code? that means pending

        context      = test.context
        return_value = nil
        begin
          context.__phase__ = phase
          return_value = context.instance_eval(&@code)
        rescue *PassthroughExceptions
          raise # passthrough-exceptions must be passed through
        rescue ::BareTest::Phase::Abortion => abortion
          test.status = BareTest::Status.new(test, abortion.status, phase, abortion.message, abortion)
        rescue Exception => exception
          handler = test.custom_handler(exception)
          if handler then
            handler.call(self, test, exception)
          else
            error(test, exception)
          end
        else
          unless test.status then
            test.status = return_value ? nil : fail(test, "Verification failed (evaluated to nil or false)")
          end
        end
      end

      def inspect
        sprintf "#<%s %p>", self.class, @description
      end
    end
  end
end
