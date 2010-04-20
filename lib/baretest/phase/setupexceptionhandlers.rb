#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  module Phase
    # Experimental
    # Define handlers for specific exception classes. The handler gets
    # the assertion, the phase and the exception yielded and is expected
    # to return a BareTest::Status.
    class SetupExceptionHandlers
      def initialize(*exception_classes, &block)
        exception_classes.each do |exception_class|
          raise "Already registered a verification exception handler for class #{exception_class}" if @verification_exception_handlers[exception_class]
          @verification_exception_handlers[exception_class] = block
        end
      end

      def description_variables
        {}
      end

      def length
        1
      end

      def setup(context)
      end

      def inspect
        sprintf "#<%s>", self.class
      end
    end
  end
end
