#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/assertion/context'
require 'baretest/assertion/failure'
require 'baretest/assertion/skip'
require 'baretest/status'



module BareTest
  class Unit
    attr_reader :setups
    attr_reader :execute
    attr_reader :verifications
    attr_reader :teardowns

    def initialize(suite, execute)
      @suite         = suite
      @setups        = nil
      @execute       = execute
      @verifications = []
      @teardowns     = nil
    end

    def out_of_order(verification)
      @verifications      << []
      @verifications.last << verification
    end

    def in_order(verification)
      @verifications      << [] if @verifications.empty?
      @verifications.last << verification
    end
  end
end
