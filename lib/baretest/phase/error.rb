#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase/abortion'



module BareTest
  class Phase
    class Error < Abortion
      attr_reader :original_exception
      def initialize(phase, original_exception)
        super(phase, "An error occurred")
        @original_exception = original_exception
      end

      def status
        :error
      end
    end
  end
end
