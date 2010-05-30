
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
          skip_recursively(suite, "Ancestor was skipped")
        elsif skipped then
          skip_suite(suite, "Container was skipped")
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
      rv = assertion.execute(setup, assertion.suite.ancestry_teardown)
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
    def interpolated_description(assertion, setups)
      setups = setups ? setups.select { |s| s.component } : []
      substitutes = {}
      setups.each do |setup| substitutes[setup.component] = setup.substitute end
      assertion.interpolated_description(substitutes)
    end
