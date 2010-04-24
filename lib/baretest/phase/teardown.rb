#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Phase
    class Teardown < Phase
      def phase
        :teardown
      end
    end
  end
end
