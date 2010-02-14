#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  # Encapsulates a single setup block and associated information.
  # Relevant for setup variants.
  Setup = Struct.new(:component, :substitute, :value, :block) do
    def inspect
      sprintf "#<Setup component=%s substitute=%p value=%p>", component, substitute, value
    end
  end
end