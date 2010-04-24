#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Phase
    class Setup < Phase
      def initialize(&block)
        @code = block
      end

      def phase
        :setup
      end

      def description_variables
        {}
      end

      def length
        1
      end

      def inspect
        sprintf "#<%s>", self.class
      end
    end
  end
end
