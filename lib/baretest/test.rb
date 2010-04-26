#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/context'



module BareTest
  class Test
    attr_reader :unit
    attr_reader :setups
    attr_reader :exercise
    attr_reader :verification
    attr_reader :teardowns

    def initialize(unit, setups, exercise, verification, teardowns)
      @unit         = unit
      @setups       = setups
      @exercise     = exercise
      @verification = verification
      @teardowns    = teardowns
    end

    def nesting_level
      @unit.nesting_level
    end

    def custom_handler(exception)
      # handled_by      = handlers && handlers.find { |handling, handler| exception_class <= handling }
      nil
    end

    def description
      variables = {}
      @setups.each do |setups| setups.each do |setup|
        variables.update(setup.description_variables)
      end end
      
      [
        interpolate(@exercise.description, variables),
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
