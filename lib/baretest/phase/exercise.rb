#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase'



module BareTest
  class Phase
    class Exercise < Phase
      attr_reader :description

      def initialize(description, &code)
        super(&code)
        @description   = description
      end

      def phase
        :exercise
      end

      def inspect
        sprintf "#<%s %p>", self.class, @description
      end
    end
  end
end
