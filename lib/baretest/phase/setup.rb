#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase'



module BareTest
  class Phase
    class Setup < Phase
      attr_reader :id

      def initialize(id=nil, variables=nil, &block)
        @id                        = id
        @code                      = block
        @has_description_variables = !!variables
        @description_variables     = variables
      end

      def phase
        :setup
      end

      def description_variables?
        @has_description_variables
      end

      def description_variables
        @description_variables || {}
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



require 'baretest/phase/setupblockvariants'
require 'baretest/phase/setupexceptionhandlers'
require 'baretest/phase/setuprequire'
require 'baretest/phase/setuptabulardata'
