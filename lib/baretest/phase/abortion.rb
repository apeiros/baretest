#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Phase
    class Abortion < StandardError
      attr_reader :phase

      def initialize(phase, message)
        super(message)
        @phase = phase
      end

      def status
        :error
      end
    end
  end
end
