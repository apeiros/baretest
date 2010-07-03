#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class SetupConstructor
    def initialize(suite, id, existing, file, line)
      @suite     = suite
      @id        = id
      @existing  = existing
      @user_file = file
      @user_line = line
    end

    def values(values, &code)
      if values.kind_of?(Array) || values.kind_of?(Hash)
        if @existing then
          @existing.add_variant(values, &code)
        else
          add_setup Phase::SetupBlockVariants.new(@id, values, &code)
        end
      else
        raise TypeError, "Array or Hash expected for values, but got #{values.class}"
      end
    end

    def add_setup(setup)
      @suite.add_setup setup, @user_file, @user_line
    end
  end
end
