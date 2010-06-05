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
    PassthroughExceptions = [
      ::NoMemoryError,
      ::SignalException,
      ::Interrupt,
      ::SystemExit,
    ]

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
    attr_reader :status

    def initialize(unit, setups, exercise, verification, teardowns)
      @unit                = unit
      @setups              = setups
      @exercise            = exercise
      @verification        = verification
      @teardowns           = teardowns
      @context             = BareTest::Context.new(self)
      @status              = nil
      @handlers            = nil
      @level               = nil
      @teardown_from       = nil
      @status_final = false
    end

    def initialize_copy(original)
      @context       = BareTest::Context.new(self)
      @status        = nil
      @teardown_from = nil
    end

    # * The return value is only considered in 'verify' blocks. Those have to
    #   return a trueish value. Nil and false make the verify fail.
    # * Setting the test status to failure is only allowed in verify and teardown.
    # * Setting the test status to pending is always final
    # * Setting the test status to skipped is always final
    # * Setting the test status to error is final in setup, verify and teardown,
    #   but NOT in exercise (this is to allow testing for exceptions being raised)
    # * If there's no test status set at the end of all phases, the test status
    #   becomes set to success
    def set_status(status)
      unless @status_final then
        @status       = status
        if status then
          case status.code
            when :pending, :skipped
              @status_final = true
            when :error
              @status_final = true if [:setup, :verification, :teardown].include?(status.phase)
            when :failure
              unless [:setup, :verification, :teardown].include?(status.phase) then
                raise "Invalid operation, tried to set test-status to failure "\
                      "while neither in verify nor teardown"
              end
            when :success
              @status ||= status
              @status_final = true
          end
        end
      end
    end

    def status_final!
      @status_final = true
    end

    def run_setup
      count          = @setups.find_index { |setup| !execute(setup) }
      @teardown_from = @unit.teardown_count_for_setup_count(count)
    end

    def run_exercise_and_verify
      unless @status then
        run_exercise
        run_verify
      end
    end

    def run_exercise
      execute(@exercise)
      #p :post_exercise => @status
    end

    def run_verify
      execute(@verification)
      #p :post_verify => @status
    end

    def run_teardown
      @teardowns.first(@teardown_from).reverse.find { |teardown|
        !execute(teardown)
      }
      @status_final = !!@status
    end

    # Returns true on success, false on every other status
    def execute(phase)
      phase.execute(self)
      true
    rescue *PassthroughExceptions
      raise # passthrough-exceptions must be passed through
    rescue ::BareTest::Phase::Abortion => abortion
      set_status(BareTest::Status.new(self, abortion.status, phase.phase, abortion.message, abortion))
      false
    rescue ::BareTest::Context::NotReturned
      false
    rescue Exception => exception
      #p :rescued => exception, :phase => phase.phase
      handler = custom_handler(exception)
      if handler then
        handler.call(phase, self, exception)
      else
        set_status(BareTest::Status.new(self, :error, phase.phase, "#{exception.class}: #{exception}", exception)) unless @status_final
        #p :rescue_set_state => @status, :status_final => @status_final
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
