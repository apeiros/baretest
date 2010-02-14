#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Assertion

    # Serves as the exercise- and verify-container for Assertions. Upon
    # Assertion#execute, a new Context is created, the setups, the assertions'
    # defining block and the teardowns instance evaled.
    # Components will want to extend this class.
    class Context

      # The Assertion instance this Context was created for
      attr_reader :__assertion__
      alias assertion __assertion__

      # Accepts the Assertion instance this Context is created for as first
      # and only argument.
      def initialize(assertion)
        @__assertion__ = assertion
      end
    end
  end
end
