#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test

	# Run is the envorionment in which the suites and asserts are executed.
	# Prior to the execution, the Run instance extends itself with the
	# formatter given.
	# Your formatter can override:
	# * run_all
	# * run_suite
	# * run_test
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
		def initialize(suite, opts=nil)
			@suite       = suite
			@inits       = []
			@options     = opts || {}
			@format      = @options[:format]
			@count       = @options[:count] || Hash.new(0)
			@interactive = @options[:interactive]

			# Add the mock adapter and initialize it
			extend(Test.mock_adapter) if Test.mock_adapter

			# Extend with the output formatter
			require "test/run/#{@format}" if @format
			extend(Test.extender["test/run/#{@format}"]) if @format

			# Extend with irb dropout code
			require "test/irb_mode" if @interactive
			extend(Test::IRBMode) if @interactive

			# Initialize extenders
			@inits.each { |init| instance_eval(&init) }
		end

		# Hook initializers for extenders
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
			suite.tests.each do |test|
				run_test(test)
			end
			suite.suites.each do |suite|
				run_suite(suite)
			end
			@count[:suite] += 1
		end

		# Formatter callback.
		# Invoked once for every assertion.
		# Gets the assertion to run as single argument.
		def run_test(assertion)
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
