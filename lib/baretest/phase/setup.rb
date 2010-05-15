#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase'



module BareTest
  class Phase
    class Setup < Phase
      def initialize(&block)
        @code = block
      end

      def phase
        :setup
      end

      def description_variables?
        false
      end

      def description_variables
        {}
      end

      def length
        1
      end

      def [](index)
        self
      end

      def inspect
        sprintf "#<%s>", self.class
      end
    end
  end
end



require 'baretest/phase/setupblock'
require 'baretest/phase/setupexceptionhandlers'
require 'baretest/phase/setuprequire'
require 'baretest/phase/setuptabulardata'
