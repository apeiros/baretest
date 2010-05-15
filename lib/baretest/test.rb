#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/context'



module BareTest
  class Test
    # The exceptions baretest will not rescue
    # NoMemoryError::   a no-memory error means we don't have enough memory to continue
    # SignalException:: something sent the process a signal to terminate
    # Interrupt::       Ctrl-C was issued, the process should terminate immediatly
    # SystemExit::      the process terminates
    PassthroughExceptions = [::NoMemoryError, ::SignalException, ::Interrupt, ::SystemExit]

    def self.interpolate(description, variables)
      if variables.empty? then
        description
      else
        keys_group = /(#{Regexp.union(variables.keys)})/
        match_keys = /
          :#{keys_group}\b  |
          :\{#{keys_group}\}
        /x
        description = description.gsub(match_keys) { |m|
          variables[($1 || $2)].to_s
        }
        match_keys = /
          @#{keys_group}\b  |
          @\{#{keys_group}\}
        /x
        description.gsub(match_keys) { |m|
          variables[($1 || $2)].inspect
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
      count          = @setups.find_index { |setup| !execute(setup) }
      @teardown_from = @unit.teardown_count_for_setup_count(count)
    end

    def exercise_and_verify
      unless @status then
        execute(@exercise)
        execute(@verification)
      end
    end

    def teardown
      @teardowns.first(@teardown_from).reverse.find { |teardown|
        !execute(teardown)
      }
      @status_unchangeable = !!@status
    end

    # Returns true on success, false on every other status
    def execute(phase)
      phase.execute(self)
      true
    rescue *PassthroughExceptions
      raise # passthrough-exceptions must be passed through
    rescue ::BareTest::Phase::Abortion => abortion
      @status = BareTest::Status.new(self, abortion.status, @context, abortion.message, abortion) unless @status_unchangeable
      false
    rescue Exception => exception
      handler = custom_handler(exception)
      if handler then
        handler.call(phase, self, exception)
      else
        @status = BareTest::Status.new(self, :error, phase.phase, "#{exception.class}: #{exception}", exception) unless @status_unchangeable
      end
      false
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
