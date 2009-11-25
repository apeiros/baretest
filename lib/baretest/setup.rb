#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  Setup = Struct.new(:substitute, :value, :block) do
    def inspect
      sprintf "#<Setup substitute=%p value=%p>", substitute, value
    end
  end
end