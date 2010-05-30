#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Phase
    class Abortion < StandardError
      attr_reader :phase

      # Runs sprintf over message with *args if additional args are given.
      # Particularly useful with %p and %s.
      def initialize(phase, message, *variables)
        @phase  = phase
        message = sprintf message, *variables unless variables.empty?
        super(message)
      end

      def status
        :error
      end
    end
  end
end



require 'baretest/phase/error'
require 'baretest/phase/failure'
require 'baretest/phase/pending'
require 'baretest/phase/skip'
