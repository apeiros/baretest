#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  # Run is the environment in which the suites and asserts are executed.
  # Prior to the execution, the Run instance extends itself with the
  # formatter given.
  # Your formatter can override:
  # :run_all::   Invoked once, before the first run_suite is ran. No arguments.
  # :run_suite:: Invoked per suite. Takes the suite to run as argument.
  # :run_test::  Invoked per assertion. Takes the assertion to execute as argument.
  #
  # Don't forget to call super within your overrides, or the tests won't be
  # executed.
  class Run
    # The toplevel suite.
    attr_reader :suite

    # The initialisation blocks of extenders
    attr_reader :inits

    # Some statistics, standard count keys are:
    # * :test - the number of tests executed until now
    # * :suite - the number of suites executed until now
    # * :success - the number of tests with status :success
    # * :failure - the number of tests with status :failure
    # * :pending - the number of tests with status :pending
    # * :skipped - the number of tests with status :skipped
    # * :error - the number of tests with status :error
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
      @suite       = suite
      @inits       = []
      @options     = opts || {}
      @count       = @options[:count] || Hash.new(0)

      (BareTest.extender+Array(@options[:extender])).each do |extender|
        extend(extender)
      end

      # Extend with the output formatter
      if format = @options[:format] then
        require "baretest/run/#{format}" if String === format
        extend(String === format ? BareTest.format["baretest/run/#{format}"] : format)
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
      run_suite(@suite)
    end

    # Formatter callback.
    # Invoked once for every suite.
    # Gets the suite to run as single argument.
    # Runs all assertions and nested suites.
    def run_suite(suite)
      suite.assertions.each do |test|
        run_test_variants(test)
      end
      suite.suites.each do |(description, suite)|
        run_suite(suite)
      end
      @count[:suite] += 1
    end

    # Invoked once for every assertion.
    # Iterates over all variants of an assertion and invokes run_test
    # for each.
    def run_test_variants(test)
      test.suite.each_component_variant do |setups|
        run_test(test, setups)
      end
    end

    # Formatter callback.
    # Invoked once for every variation of an assertion.
    # Gets the assertion to run as single argument.
    def run_test(assertion, setup)
      assertion.setups = setup
      rv = assertion.execute
      @count[:test]            += 1
      @count[assertion.status] += 1
      rv
    end

    # Status over all tests ran up to now
    # Can be :error, :failure, :incomplete or :success
    # The algorithm is a simple fall through:
    # if any test errored, then global_status is :error,
    # if not, then if any test failed, global_status is :failure,
    # if not, then if any test was pending or skipped, global_status is :incomplete,
    # if not, then global_status is success
    def global_status
      case
        when @count[:error]   > 0 then :error
        when @count[:failure] > 0 then :failure
        when @count[:pending] > 0 then :incomplete
        when @count[:skipped] > 0 then :incomplete
        else :success
      end
    end
  end
end
