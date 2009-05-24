require 'test/support'



module Test
	@extender     = {}
	@mock_adapter = nil

	class <<self
		# A hash of extenders (require-string => module) to be used with Test::Run.
		attr_reader :extender

		# For mock integration
		attr_reader :mock_adapter

		# The main run instance. That's the one run_if_mainfile adds suites and
		# assertions to.
		attr_reader :run
	end

	# Adds the contained assertions and suites to the toplevel suite
	def self.define(name=nil, opts={}, &block)
		if @run && name then
			@run.suite.suite(name, opts, &block)
		else
			@run = Run.new(name, opts, &block)
		end
	end

	# Creates a Test::Run instance, adds the assertions and suites defined in its
	# own block to that Test::Run instance's toplevel suite and if $PROGRAM_NAME
	# (aka $0) is equal to __FILE__ (means the current file is the file directly
	# executed by ruby, and not just required/loaded/evaled by another file),
	# subsequently also runs that suite.
	def self.run_if_mainfile(name=nil, opts={}, &block)
		define(name, opts, &block)
		return unless caller.first[/^[^:]*/] == $0
		@run.run(ENV['FORMAT'] || 'cli')
	end

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

		def initialize(name=nil, opts={}, &block)
			@suite = Suite.create(name, nil, opts, &block)
		end

		# Run the toplevel suite.
		# Calls run_all with the toplevel suite as argument and a block that
		# calls run_suite with the yielded argument (which should be the toplevel
		# suite).
		def run(runner, count=Hash.new(0))
			require "test/run/#{runner}"
			extend(Test.extender["test/run/#{runner}"])
			extend(Test.mock_adapter) if Test.mock_adapter
			@count = count
			run_all(@suite) do |main_suite|
				run_suite(main_suite)
			end
		end

		# Formatter callback.
		# Invoked once at the beginning.
		# Gets the toplevel suite as single argument.
		def run_all(suites)
			yield(suites)
		end

		# Formatter callback.
		# Invoked once for every suite.
		# Gets the suite to run as single argument.
		# Runs all assertions and nested suites.
		def run_suite(suite)
			suite.tests.each do |test|
				run_test(test) do |assertion|
					assertion.execute
				end
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
			rv = yield(assertion)
			@count[:test]            += 1
			@count[assertion.status] += 1
			rv
		end
	end

	# A Suite is a container for multiple assertions.
	# You can give a suite a name, also a suite can contain
	# setup and teardown blocks that are executed before (setup) and after
	# (teardown) every assertion.
	# Suites can also be nested. Nested suites will inherit setup and teardown.
	class Suite

		# Nested suites
		attr_reader :suites

		# All assertions in this suite
		attr_reader :tests

		# This suites name. Toplevel suites usually don't have a name.
		attr_reader :name

		# This suites direct parent. Nil if toplevel suite.
		attr_reader :parent

		# An Array containing the suite itself (first element), then its direct
		# parent suite, then that suite's parent and so on
		attr_reader :ancestors

		def self.create(name=nil, parent=nil, opts={}, &block)
			Array(opts[:requires]).each { |file| require file } if opts[:requires]
		rescue LoadError
			# A suite is skipped if requirements are not met
			Skipped::Suite.new(name, parent, &block)
		else
			# All suites within Skipped::Suite are Skipped::Suite
			(block ? self : Skipped::Suite).new(name, parent, &block)
		end

		def initialize(name=nil, parent=nil, &block)
			@name      = name
			@parent    = parent
			@suites    = []
			@tests     = []
			@setup     = []
			@teardown  = []
			@ancestors = [self] + (@parent ? @parent.ancestors : [])
			instance_eval(&block) if block
		end

		# Define a nested suite.
		# Nested suites inherit setup & teardown methods.
		# Also if an outer suite is skipped, all inner suites are skipped too.
		# Valid values for opts:
		# requires
		# :   A list of files to require, if one of the requires fails, the suite
		#     will be skipped. Accepts a String or an Array
		def suite(name=nil, opts={}, &block)
			@suites << self.class.create(name, self, opts, &block)
		end

		# Define a setup block for this suite. The block will be ran before every
		# assertion once, even for nested suites.
		def setup(&block)
			block ? @setup << block : @setup
		end

		# Define a teardown block for this suite. The block will be ran after every
		# assertion once, even for nested suites.
		def teardown(&block)
			block ? @teardown << block : @teardown
		end

		# Define an assertion. The block is supposed to return a trueish value
		# (anything but nil or false).
		# See Assertion for more info.
		def assert(message=nil, &block)
			@tests << Assertion.new(self, message, &block)
		end
	end

	# Defines an assertion
	# An assertion belongs to a suite and consists of a message and a block.
	# The verify the assertion, the suite's (and its ancestors) setup blocks are
	# executed, then the assertions block is executed and after that, the suite's
	# (and ancestors) teardown blocks are invoked.
	#
	# An assertion has 5 possible states, see Assertion#status for a list of them.
	#
	# There are various helper methods in lib/test/support.rb which help you
	# defining nicer diagnostics or just easier ways to test common scenarios.
	# The following are test helpers:
	# * Kernel#raises(exception_class=StandardError)
	# * Kernel#within_delta(a, b, delta)
	# * Kernel#equal_unordered(a,b)
	# * Enumerable#equal_unordered(other)
	class Assertion

		# An assertion has 5 possible states:
		# :success
		# :    The assertion passed. This means the block returned a trueish value.
		# :failure
		# :    The assertion failed. This means the block returned a falsish value.
		#      Alternatively it raised a Test::Failure (NOT YET IMPLEMENTED).
		#      The latter has the advantage that it can provide nicer diagnostics.
		# :pending
		# :    No block given to the assertion to be run
		# :skipped
		# :    If one of the parent suites is missing a dependency, its assertions
		#      will be skipped
		# :error
		# :    The assertion errored out. This means the block raised an exception
		attr_reader :status

		# If an exception occured in Assertion#execute, this will contain the
		# Exception object raised.
		attr_reader :exception

		# The description of this assertion.
		attr_reader :message

		# suite
		# :   The suite the Assertion belongs to
		# message
		# :   A descriptive string about what this Assertion tests.
		# &block
		# :   The block definition. Without one, the Assertion will have a :pending
		#     status.
		def initialize(suite, message, &block)
			@suite     = suite
			@status    = nil
			@exception = nil
			@message   = message || "No message given"
			@block     = block
		end

		# Runs the assertion and sets the status and exception
		def execute
			@exception = nil
			if @block then
				# run all setups in the order of their nesting (outermost first, innermost last)
				@suite.ancestors.map { |suite| suite.setup }.flatten.reverse.each { |setup| instance_eval(&setup) }
				# run the assertion
				@status = instance_eval(&@block) ? :success : :failure
				# run all teardowns in the order of their nesting (innermost first, outermost last)
				@suite.ancestors.map { |suite| suite.teardown }.flatten.each { |setup| instance_eval(&setup) }
			else
				@status = :pending
			end
		rescue => e
			@exception, @status = e, :error
			self
		else
			self
		end
	end

	# Skipped contains variants of Suite and Assertion.
	# See Skipped::Suite and Skipped::Assertion
	module Skipped
		# Like Test::Suite, but all Assertions are defined as Skipped::Assertion
		class Suite < ::Test::Suite
			# :nodoc:
			# All Assertions use Skipped::Assertion instead of Test::Assertion.
			def assert(message=nil, &block)
				@tests << Skipped::Assertion.new(self, message, &block)
			end

			# :nodoc:
			# All setup blocks are disabled
			def setup(&block)
				[]
			end

			# :nodoc:
			# All teardown blocks are disabled
			def teardown(&block)
				[]
			end
		end

		# Like Test::Assertion, but fakes execution and sets status always to
		# skipped.
		class Assertion < ::Test::Assertion
			def execute() @status = :skipped and self end
		end
	end
end
