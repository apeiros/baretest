#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase/setup'



module BareTest
  class Phase
    class TabularDataSetup < Setup
      def execute(test)
        test.context.instance_eval(&@block)
        true
      end

      def description_variables?
        true
      end

      def inspect
        sprintf "#<%s>", self.class
      end
    end
  end
end
