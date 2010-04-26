#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/formatter'
require 'baretest/persistence'
require 'baretest/status'
require 'baretest/statuscollection'
require 'baretest/test'



module BareTest

  # Run is the environment in which the suites and assertions are executed.
  # Prior to the execution, the Run instance extends itself with the
  # formatter that should be used and other runner related toolsets.
  # Your formatter can override:
  # :run_all::            Invoked once, before the first run_suite is ran. No
  #                       arguments.
  # :run_suite::          Invoked per suite. Takes the suite to run as argument.
  # :run_test_variants::  Invoked per assertion. Takes the assertion to execute
  #                       as argument.
  # :run_test::           Invoked per setup variation of each assertion. Takes
  #                       the assertion to execute and the setup blocks to use
  #                       as arguments.
  #
  # Don't forget to call super within your overrides, or the tests won't be
  # executed.
  class Run
    # The toplevel suite.
    attr_reader :suite

    # The initialisation blocks of extenders
    attr_reader :inits

    # Some statistics, standard count keys are:
    # :test::    the number of tests executed until now
    # :suite::   the number of suites executed until now
    # <status>:: the number of tests with that status (see
    #            BareTest::StatusOrder for a list of states)
    attr_reader :count

    attr_reader :global_status

    # Run the passed suite.
    # Calls run_all with the toplevel suite as argument and a block that
    # calls run_suite with the yielded argument (which should be the toplevel
    # suite).
    # Options accepted:
    # * :extenders:   An Array of Modules, will be used as argument to self.extend, useful e.g. for
    #   mock integration
    # * :format:      A string with the basename (without suffix) of the formatter to use - or a
    #   Module
    # * :interactive: true/false, will switch this Test::Run instance into IRB mode, where an error
    #   will cause an irb session to be started in the context of a clean copy of
    #   the assertion with all setup callbacks invoked
    #
    # The order of extensions is:
    # * :extender
    # * :format (extends with the formatter module)
    # * :interactive (extends with IRBMode)
    def initialize(suite, opts=nil)
      @suite              = suite
      @inits              = []
      @options            = opts || {}
      @options[:input]  ||= $stdin
      @options[:output] ||= $stdout
      @count              = @options[:count] || Hash.new(0)
      @provided           = [] # Array's set operations are the fastest
      @include_tags       = @options[:include_tags]   # nil is ok here
      @exclude_tags       = @options[:exclude_tags]   # nil is ok here
      include_states      = @options[:include_states] # nil is ok here
      exclude_states      = @options[:exclude_states] # nil is ok here
      @states             = [nil, *BareTest::StatusOrder]
      @skipped            = {}
      @last_run_states    = {}
      @persistence        = @options[:persistence]

      if (include_states || exclude_states) && !((include_states && include_states.empty?) && (exclude_states && exclude_states.empty?)) then
        [include_states, exclude_states].compact.each do |states|
          states << nil if states.include?(:new)
          states.push(:error, :skipped, :pending) if states.include?(:failure)
          states.delete(:new)
          if states.include?(:skipped) then
            states.delete(:skipped)
            states.push(:pending, :manually_skipped, :dependency_missing, :library_missing, :component_missing)
          end
          states.uniq!
        end
        @states = (include_states || @states) - (exclude_states || [])
      end

      (BareTest.extender+Array(@options[:extender])).each do |extender|
        extend(extender)
      end

      # Extend with the output formatter
      formatter  = @options[:format] || 'none'
      @formatter = BareTest::Formatter.load(formatter).new(self, @options)

      # Extend with irb dropout code
      extend(BareTest::IRBMode) if @options[:interactive]

      # Initialize extenders
      @inits.each { |init| instance_eval(&init) }
    end

    # Hook initializers for extenders.
    # Blocks passed to init will be instance_eval'd at the end of initialize.
    # Example usage:
    #   module ExtenderForRun
    #     def self.extended(run_obj)
    #        run_obj.init do
    #          # do some initialization stuff for this module
    #        end
    #     end
    #   end
    def init(&block)
      @inits << block
    end

    def run
      start  = Time.now
      @formatter.start_all
      @global_status = run_suite(@suite)
      @formatter.end_all(@global_status, Time.now-start)
    end

    def run_suite(suite)
      #p :run_suite => suite.description
      start  = Time.now
      status = StatusCollection.new(suite)
      @formatter.start_suite(suite)
      suite.children.each do |child|
        case child
          when BareTest::Suite
            status.update(run_suite(child))
          when BareTest::Unit
            status.update(run_unit(child))
        end
      end
      @formatter.end_suite(suite, status, Time.now-start)
      status
    end

    def run_unit(unit)
      #p :run_unit_in_suite => unit.suite.description
      start  = Time.now
      status = StatusCollection.new(unit)
      @formatter.start_unit(unit)
      unit.verifications.each do |out_of_order_verifications|
        out_of_order_verifications.each do |verification|
          setups    = unit.suite.ancestral_setup
          exercise  = unit.exercise
          teardowns = unit.suite.ancestral_teardown
          # setup variants
            #p :suite => unit.suite.description, :exercise => unit.exercise.description, :verification => verification.description, :setup => unit.suite.ancestral_setup, :teardown => unit.suite.ancestral_teardown
            test    = Test.new(unit, setups, exercise, verification, teardowns)
            status << run_test(test)
          # end setup variants
        end
      end
      @formatter.end_unit(unit, status, Time.now-start)
      status
    end

    # Returns the number of possible setup variations.
    # See #each_component_variant
    def number_of_setup_variants
      return 0 if @setups.empty?
      @setups.inject(1) { |count, setup| count*setup.length }
    end

    # Yields all possible permutations of setup components.
    def each_setup_variant
      if @setups.empty? then
        yield([])
      else
        maximums = @setups.map { |setup| setup.length }
        number_of_setup_variants.times do |i|
          yield(setup_variant(i, maximums))
        end
      end

      self
    end

    # Return the component variants
    def setup_variant(index, maximums=nil)
      maximums ||= @setups.map { |setup| setup.length }
      process    = maximums.map { |e|
        index, partial = index.divmod(e)
        partial
      }
      @setups.zip(process).map { |setup, partial| setup[partial] }
    end

    def run_test(test)
      start   = Time.now
      @formatter.start_test(test)
      context = BareTest::Context.new(test)
      status  = nil

      # run setups as far as we get without an exception
      level   = (0...test.setups.size).find { |level|
        status = test.setups[level].find { |setup|
          setup.execute(context, test)
        }
      }

      # run exercise and verify
      status ||= test.exercise.execute(context, test)
      status ||= test.verification.execute(context, test)

      # run teardowns from the highest we got when running the setups
      level  ||= test.setups.size-1
      level.downto(0) { |level|
        teardown_status = test.teardowns[level].find { |teardown|
          teardown.execute(context, test)
        }
        status = teardown_status if teardown_status # teardown overrides any previous status, fixme, accumulate instead
      }

      # if nothing has yet set a status, then it's a success, hurray.
      status ||= Status.new(test, :success)

      @formatter.end_test(test, status, Time.now-start)

      status
    end
  end
end
