#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Assertion
    class Context
      attr_reader :__assertion__
      alias assertion __assertion__

      def initialize(assertion)
        @__assertion__ = assertion
      end
    end
  end
end
