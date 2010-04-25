#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/context'



module BareTest
  class Unit
    attr_reader :suite
    attr_reader :exercise
    attr_reader :verifications

    def initialize(suite, exercise)
      @suite         = suite
      @exercise      = exercise
      @verifications = []
    end

    def finish
    end

    def nesting_level
      @suite.nesting_level+1
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
