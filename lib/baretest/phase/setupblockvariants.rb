#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase/setup'
require 'baretest/phase/setupblockwithdata'



module BareTest
  class Phase
    class SetupBlockVariants < Setup
      def initialize(id, variant, &block)
        super(id, &nil)
        @multiple = []
        add_variant(id, variant, &block)
      end

      def length
        @multiple.length
      end

      def add_variant(id, variant, &block)
        case variant
          when String
            @multiple << SetupBlockWithData.new(id, variant, variant, &block)
          when Array
            @multiple.concat variant.map { |value|
              SetupBlockWithData.new(id, value, value, &block)
            }
          when Hash
            @multiple.concat variant.map { |key, value|
              SetupBlockWithData.new(id, key, value, &block)
            }
        end
        
        self
      end

      def [](index)
        @multiple[index]
      end
    end
  end
end
