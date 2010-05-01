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
    attr_reader :context

    attr_accessor :status

    def initialize(unit, setups, exercise, verification, teardowns)
      @unit         = unit
      @setups       = setups
      @exercise     = exercise
      @verification = verification
      @teardowns    = teardowns
      @context      = BareTest::Context.new(self)
      @status       = nil
      @handlers     = nil
    end

    def nesting_level
      @unit.nesting_level
    end

    def register_custom_handler(exception_class, &handler)
      @handlers ||= {}
      raise ArgumentError, "Multiple handlers defined for #{exception_class}" if @handlers.has_key?(exception_class)
      @handlers[exception_class] = handler
    end

    def custom_handler(exception)
      return nil unless @handlers
      @handlers.values_at(*exception.class.ancestors).compact.first
    end

    def description
      template  = "#{@exercise.description} #{@verification.description}"
      variables = {}
      @setups.each do |setups| setups.each do |setup|
        variables.update(setup.description_variables)
      end end

      interpolate(template, variables)
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
