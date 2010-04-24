#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Phase
    class TabularDataSetup < Setup
      def execute(context, unit)
        context.instance_eval(&@block)
        true
      end

      def inspect
        sprintf "#<%s>", self.class
      end
    end
  end
end