require 'test/support'



module Test
	@extender, @mock_adapter = {}, nil
	class <<self
		attr_reader :extender, :mock_adapter, :run
	end

	def self.run_if_mainfile(&block)
		(@run ||= Run.new).suite.instance_eval(&block)
		return unless caller.first[/^[^:]*/] == $0
		@run.run(ENV['FORMAT'] || 'cli')
	end

	class Run
		attr_reader :suite

		def initialize()
			@suite = Suite.new
		end

		def run(runner, count=Hash.new(0))
			require "test/run/#{runner}"
			extend(Test.extender["test/run/#{runner}"])
			extend(Test.mock_adapter) if Test.mock_adapter
			@count = count
			run_all(@suite) do |main_suite| run_suite(main_suite) end
		end

		def run_all(suites) yield(suites) end
		def run_suite(suite)
			suite.tests.each do |test|
				run_test(test) { |assertion| assertion.execute }
				@count[:test] += 1
				@count[test.status] += 1
			end
			suite.suites.each do |suite| run_suite(suite) end
			@count[:suite] += 1
		end
		def run_test(assertion) yield(assertion) end
	end

	class Suite
		attr_reader :suites, :tests, :name, :parent, :ancestors

		def initialize(name=nil, parent=nil, &block)
			@name, @parent, @suites, @tests, @setup, @teardown = name, parent, [], [], [], []
			@ancestors = [self] + (@parent ? @parent.ancestors : [])
			instance_eval(&block) if block
		end

		def suite(name=nil, opts={}, &block)
			begin
				Array(opts[:requires]).each { |file| require file } if opts[:requires]
			rescue LoadError
				@suites << suite = Skipped::Suite.new(name, self)
			else
				# All suites within Skipped::Suite are Skipped::Suite
				@suites << suite = (block ? self.class : Skipped::Suite).new(name, self)
			end
			suite.instance_eval(&block)
		end

		# Define a setup block for this suite. The block will be ran before every
		# assertion once, even for nested suites.
		def setup(&block) block ? @setup << block : @setup end

		# Define a teardown block for this suite. The block will be ran after every
		# assertion once, even for nested suites.
		def teardown(&block) block ? @teardown << block : @teardown end

		# Define an assertion. The block is supposed to return a trueish value
		# (anything but nil or false).
		#
		# An assertion has 5 possible states:
		# success
		# :    The assertion passed. This means the block returned a trueish value.
		# failure
		# :    The assertion failed. This means the block returned a falsish value.
		#      Alternatively it raised a Test::Failure (NOT YET IMPLEMENTED).
		#      The latter has the advantage that it can provide nicer diagnostics.
		# pending
		# :    No block given to the assertion to be run
		# skipped
		# :    If one of the parent suites is missing a dependency, its assertions
		#      will be skipped
		# error
		# :    The assertion errored out. This means the block raised an exception
		#
		# There are various helper methods in lib/test/support.rb which help you
		# defining nicer diagnostics or just easier ways to test common scenarios.
		# The following are test helpers:
		# * Kernel#raises(exception_class=StandardError)
		# * Kernel#within_delta(a, b, delta)
		# * Kernel#equal_unordered(a,b)
		# * Enumerable#equal_unordered(other)
		def assert(message=nil, &block) @tests << Assertion.new(self, message, &block) end
	end

	class Assertion
		attr_reader :status, :exception, :message
		def initialize(suite, message, &block)
			@suite, @status, @exception, @message, @block = suite, nil, nil, (message || "No message given"), block
		end

		def execute
			if @block
				# run all setups in the order of their nesting (outermost first, innermost last)
				@suite.ancestors.map { |suite| suite.setup }.flatten.reverse.each { |setup| instance_eval(&setup) }
				# run the assertion
				@status = instance_eval(&@block) ? :success : :failure
				# run all teardowns in the order of their nesting (innermost first, outermost last)
				@suite.ancestors.map { |suite| suite.teardown }.flatten.each { |setup| instance_eval(&setup) }
			else @status = :pending end
		rescue => e
			@exception, @status = e, :error
			self
		else self end
	end

	module Skipped
		class Suite < ::Test::Suite
			def assert(message=nil, &block) @tests << Skipped::Assertion.new(self, message, &block) end
			def setup(&block) [] end
			def teardown(&block) [] end
		end
		class Assertion < ::Test::Assertion
			def execute() @status = :skipped and self end
		end
	end

	@main_suite = Suite.new
end
