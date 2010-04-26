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

      def execute(context, test)
        return pending(context, test, "No code provided") unless @code # no code? that means pending
        return_value = nil
        begin
          context.__phase__ = phase
          return_value = context.instance_eval(&@code)
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
          return_value ? nil : fail(context, test, "Verification failed (evaluated to nil or false)")
        end
      end

      def inspect
        sprintf "#<%s %p>", self.class, @description
      end
    end
  end
end
