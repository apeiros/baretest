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
  class Test
    attr_reader :setups
    attr_reader :execute
    attr_reader :verification
    attr_reader :teardowns

    attr_accessor :status

    def initialize(suite, setups, execute, verification, teardowns)
      @suite        = suite
      @setups       = setups
      @execute      = execute
      @verification = verification
      @teardowns    = teardowns
      @status       = status
    end

    def nesting_level
      @suite.nesting_level+1
    end

    def description
      variables = {}
      @setups.each do |setup|
        variables.update(setup.variables)
      end
      
      [
        interpolate(@execute.description, variables),
        interpolate(@verification.description, variables)
      ]
    end

    def interpolate(description, variables)
      if variables.empty? then
        description
      else
        description.gsub(/:(?:#{substitutes.keys.join('|')})\b/) { |m|
          substitutes[m[1..-1].to_sym]
        }
      end
    end
  end
end
