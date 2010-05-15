#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class SetupConstructor
    def initialize(suite, id, existing)
      @suite    = suite
      @id       = id
      @existing = existing
    end

    def values(values, &code)
      if values.kind_of?(Array) || values.kind_of?(Hash)
        if @existing then
          @existing.add_variant(values, &code)
        else
          @suite.add_setup Phase::SetupBlockVariants.new(@id, values, &code)
        end
      else
        raise TypeError, "Array or Hash expected for values, but got #{values.class}"
      end
    end
  end
end
