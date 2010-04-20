#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  module Phase
    BasicSetup = Struct.new(:block) do
      def description_variables
        {}
      end

      def length
        1
      end

      def setup(context)
        context.instance_eval(&block)
        true
      end

      def inspect
        sprintf "#<%s>", self.class
      end
    end
  end
end
