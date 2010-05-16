#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase/setup'



module BareTest
  class Phase
    class SetupTabularData < Setup
      def initialize(id, string, &code)
        super(id, &nil)
        add_variant(string, &code)
      end

      def add_variant(data, &code)
        @code = code
        @data = BareTest::TabularData.new(data)
      end

      def length
        @data.length
      end

      def [](index)
        code       = @code
        table      = @data
        data       = table[index]
        desc_vars  = {}
        @data.keys.zip(data) { |key, value| desc_vars[key] = value }

        Setup.new(@id, desc_vars) {
          table.variables.zip(data) { |ivar, value|
            instance_variable_set(ivar, value)
          }
          instance_eval(code) if code
        }
      end

      def inspect
        sprintf "#<%s>", self.class
      end
    end
  end
end
