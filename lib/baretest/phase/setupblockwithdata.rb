#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase'



module BareTest
  class Phase
    class SetupBlockWithData < Setup
      def initialize(id, substitute, data, &block)
        @id                        = id
        @code                      = block
        @substitute                = substitute
        @data                      = data
        @has_description_variables = true
        @description_variables     = {id.to_s => substitute}
      end

      def execute(test)
        raise Pending.new(phase, "No code provided") unless @code # no code? that means pending
  
        context = test.context
        context.__phase__ = phase
        context.instance_exec(@data, &@code)
      end

      def inspect
        sprintf "#<%s %p %p %p>", self.class, @id, @substitute, @data
      end
    end
  end
end
