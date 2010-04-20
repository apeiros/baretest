#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  module Phase
    TabularDataSetup = Struct.new(:block) do
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
