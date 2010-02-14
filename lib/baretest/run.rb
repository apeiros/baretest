#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/persistence'



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
      @suite           = suite
      @inits           = []
      @options         = opts || {}
      @count           = @options[:count] || Hash.new(0)
      @provided        = [] # Array's set operations are the fastest
      @include_tags    = @options[:include_tags]   # nil is ok here
      @exclude_tags    = @options[:exclude_tags]   # nil is ok here
      include_states   = @options[:include_states] # nil is ok here
      exclude_states   = @options[:exclude_states] # nil is ok here
      @states          = [nil, :success, :failure, :skipped, :pending, :error]
      @skipped         = {}
      @last_run_states = {}

      @persistence    = @options[:persistence]

      if (include_states || exclude_states) && !((include_states && include_states.empty?) && (exclude_states && exclude_states.empty?)) then
        [include_states, exclude_states].compact.each do |states|
          states << nil if states.include?(:new)
          states << :pending if states.include?(:skipped)
          states.concat([:error, :skipped, :pending]) if states.include?(:failure)
          states.delete(:new)
        end
        @states = (include_states || @states) - (exclude_states || [])
      end

      (BareTest.extender+Array(@options[:extender])).each do |extender|
        extend(extender)
      end

      # Extend with the output formatter
      format = @options[:format]
      if format.is_a?(String) then
        require "baretest/run/#{format}"
        extend(BareTest.format["baretest/run/#{format}"])
      elsif format.is_a?(Module) then
        extend(format)
      end

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

    # Formatter callback.
    # Invoked once at the beginning.
    # Gets the toplevel suite as single argument.
    def run_all
      @last_run_states = @persistence ? @persistence.read('final_states', {}) : {}
      @skipped         = {}
      run_suite(@suite)
      @persistence.store('final_states', @last_run_states) if @persistence
    end

    # Formatter callback.
    # Invoked once for every suite.
    # Gets the suite to run as single argument.
    # Runs all assertions and nested suites.
    def run_suite(suite)
      missing_tags     = @include_tags && @include_tags - suite.tags
      superfluous_tags = @exclude_tags && suite.tags & @exclude_tags
      ignored          = (missing_tags && !missing_tags.empty?) || (superfluous_tags && !superfluous_tags.empty?)

      unless ignored then
        unmet_dependencies  = (suite.depends_on-@provided)
        manually_skipped    = suite.skipped?
        recursively_skipped = !unmet_dependencies.empty? || manually_skipped
        skipped             = @skipped[suite] || recursively_skipped

        if recursively_skipped then
          skip_recursively(suite, "Skipped")
        elsif skipped then
          skip_suite(suite, "Skipped")
        end
      end

      if ignored then
        states = []
      else
        states = suite.assertions.map do |test|
          run_test_variants(test)
        end
      end
      states.concat(suite.suites.map { |(description, subsuite)|
        run_suite(subsuite)
      })
      @count[:suite] += 1

      # || in case the suite contains no tests or suites
      final_status = BareTest.most_important_status(states) || :pending

      @provided |= suite.provides if final_status == :success

      Status.new(suite, final_status)
    end

    # Invoked once for every assertion.
    # Iterates over all variants of an assertion and invokes run_test
    # for each.
    def run_test_variants(assertion)
      ignored = !@states.include?(@last_run_states[assertion.id])
      skipped = @skipped[assertion] || assertion.skipped?

      if ignored then
        overall_status = nil
      elsif skipped then
        Array.new(assertion.suite.component_variant_count) { run_test(assertion, []) }
        @last_run_states[assertion.id] = :manually_skipped
        overall_status                 = :manually_skipped
      else
        states = []
        assertion.suite.each_component_variant do |setups|
          rv = run_test(assertion, setups)
          states << rv.status
        end
        overall_status                 = BareTest.most_important_status(states)
      end
      @last_run_states[assertion.id] = overall_status if overall_status

      overall_status
    end

    # Formatter callback.
    # Invoked once for every variation of an assertion.
    # Gets the assertion to run as single argument.
    def run_test(assertion, setup)
      rv = assertion.execute(setup.map { |s| s.block }, assertion.suite.ancestry_teardown)
      @count[:test]     += 1
      @count[rv.status] += 1

      rv
    end

    # Marks all assertion within this suite as skipped and the suite itself too.
    def skip_suite(suite, reason) # :nodoc:
      suite.skip(reason)
      reason = suite.reason
      suite.assertions.each do |test|
        test.skip(reason)
      end
    end

    # Marks all tests, suites and their subsuites within this suite as skipped.
    def skip_recursively(suite, reason) # :nodoc:
      skip_suite(suite, reason)
      suite.suites.each do |description, subsuite|
        skip_recursively(subsuite, reason)
      end
    end

    # Status over all tests ran up to now
    # Can be :error, :failure, :incomplete or :success
    # The algorithm is a simple fall through:
    # if any test errored, then global_status is :error,
    # if not, then if any test failed, global_status is :failure,
    # if not, then if any test was pending or skipped, global_status is :incomplete,
    # if not, then global_status is success
    def global_status
      status_counts         = @count.values_at(*BareTest::StatusOrder)
      most_important_status = BareTest::StatusOrder.zip(status_counts) { |status, count|
        break status if count > 0
      } || :success
    end

    # Get an assertions' interpolated description for a given Array of Setup
    # instances.
    # See Assertion#interpolated_description
    def interpolated_description(assertion, setup)
      setups = setups ? setups.select { |s| s.component } : []
      substitutes = {}
      setups.each do |setup| substitutes[setup.component] = setup.substitute end
      assertion.interpolated_description(substitutes)
    end
  end
end
