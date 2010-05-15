#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/context'



module BareTest
  class Test
    def self.interpolate(description, variables)
      if variables.empty? then
        description
      else
        keys_group = /(#{Regexp.union(variables.keys)})/
        match_keys = /
          [:@]#{keys_group}\b  |
          [:@]\{#{keys_group}\}
        /x
        description.gsub(match_keys) { |m|
          variables[($1 || $2)]
        }
      end
    end

    attr_reader :unit
    attr_reader :setups
    attr_reader :exercise
    attr_reader :verification
    attr_reader :teardowns
    attr_reader :context

    attr_accessor :status

    def initialize(unit, setups, exercise, verification, teardowns)
      @unit          = unit
      @setups        = setups
      @exercise      = exercise
      @verification  = verification
      @teardowns     = teardowns
      @context       = BareTest::Context.new(self)
      @status        = nil
      @handlers      = nil
      @level         = nil
      @teardown_from = nil
    end

    def setup
      count          = @setups.find_index { |setup| setup.execute(self) }
      @teardown_from = @unit.teardown_count_for_setup_count(count)
    end

    def teardown
      @teardowns.first(@teardown_from).reverse.find { |teardown|
        teardown.execute(self)
      }
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
      @setups.each do |setup|
        variables.update(setup.description_variables) if setup.description_variables?
      end

      Test.interpolate(template, variables)
    end
  end
end
