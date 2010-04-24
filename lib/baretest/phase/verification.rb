#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Phase
    class Verification < Phase
      attr_reader :description

      def initialize(description, &code)
        @description = description
        @code        = code
      end

      def phase
        :verification
      end

      def execute(*arguments)
        failure "Verification failed (evaluated to nil or false)" unless super
        true
      end

      def inspect
        sprintf "#<%s %p>", self.class, @description
      end
    end
  end
end
