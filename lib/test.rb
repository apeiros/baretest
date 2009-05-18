require 'test/support'



module Test
	@extender, @mock_adapter = {}, nil
	class <<self
		attr_reader :extender, :mock_adapter, :run
	end

	def self.run_if_mainfile(&block)
		(@run ||= Run.new).suite.instance_eval(&block)
		return unless caller.first[/^[^:]*/] == $0
		@run.run('cli')
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
		attr_reader :suites, :tests, :name, :parent

		def initialize(name=nil, parent=nil, &block)
			@name, @parent, @suites, @tests, @setup, @teardown = name, parent, [], [], [], []
			instance_eval(&block) if block
		end

		def ancestors
			ancestors, parent = [self], nil # parent must be initialized for the next line to work
			ancestors << parent while parent = ancestors.last.parent
			ancestors
		end

		def suite(name=nil, opts={}, &block)
			begin
				Array(opts[:requires]).each { |file| require file } if opts[:requires]
			rescue LoadError
				@suites << suite = Skipped::Suite.new(name, self)
			else
				@suites << suite = self.class.new(name, self) # All suites within Skipped::Suite are Skipped::Suite
			end
			suite.instance_eval(&block)
		end

		def setup(&block)
			block ? @setup << block : @setup
		end

		def teardown(&block)
			block ? @teardown << block : @teardown
		end

		def assert(message=nil, &block) @tests << Assertion.new(self, :assert, message, &block) end
		def refute(message=nil, &block) @tests << Assertion.new(self, :refute, message, &block) end
	end

	class Assertion
		attr_reader :status, :exception, :message
		def initialize(suite, action, message, &block)
			@suite, @status, @exception, @message, @action, @block = suite, nil, nil, (message || "No message given"), action, block
		end

		def execute
			if @block
				@suite.ancestors.map { |suite| suite.setup }.flatten.reverse.each { |setup| instance_eval(&setup) }
				@status = ((@action == :refute) ^ (instance_eval(&@block))) ? :success : :failure
				@suite.ancestors.map { |suite| suite.teardown }.flatten.reverse.each { |setup| instance_eval(&setup) }
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

	module Skipped
		class Suite < ::Test::Suite
			def assert(message=nil, &block) @tests << Skipped::Assertion.new(self, :assert, message, &block) end
			def refute(message=nil, &block) @tests << Skipped::Assertion.new(self, :refute, message, &block) end
			def setup(&block) [] end
			def teardown(&block) [] end
		end
		class Assertion < ::Test::Assertion
			def execute() @status = :skipped and self end
		end
	end

	@main_suite = Suite.new
end


Test.run_if_mainfile do
	# assertions and refutations can be grouped in suites. They will share
	# setup and teardown
	# they don't have to be in suites, though
	suite "Success" do
		assert "An assertion returning a trueish value (non nil/false) is a success" do
			true
		end

		refute "A refutation returning a falsish value (nil/false) is a success" do
			false
		end
	end

	suite "Failure" do
		assert "An assertion returning a falsish value (nil/false) is a failure" do
			false
		end

		refute "A refutation returning a trueish value (non nil/false) is a failure" do
			true
		end
	end

	suite "Pending" do
		assert "An assertion without a block is pending"
		refute "A refutation without a block is pending"
	end

	suite "Error" do
		assert "Uncaught exceptions in an assertion are an error" do
			raise "Error!"
		end

		refute "Uncaught exceptions in a refutation are an error" do
			raise "Error!"
		end
	end

	suite "Special assertions" do
		assert "Assert a block to raise" do
			raises do
				sleep(rand()/3+0.05)
				raise "If this raises then the assertion is a success"
			end
		end

		assert "Assert a float to be close to another" do
			a = 0.18 - 0.01
			b = 0.17
			within_delta a, b, 0.001
		end

		suite "Nested suite" do
			assert "Assert two randomly ordered arrays to contain the same values" do
				a = [*"A".."Z"] # an array with values from A to Z
				b = a.sort_by { rand }
				a.equal_unordered(b) # can be used with any Enumerable, uses hash-key identity
			end
		end
	end

	suite "Setup & Teardown" do
		setup do
			@foo = "foo"
			@bar = "bar"
		end

		assert "@foo should be set" do
			@foo == "foo"
		end

		refute "@baz is only defined for subsequent nested suite" do
			@baz == "baz"
		end

		suite "Nested suite" do
			setup do
				@bar = "inner bar"
				@baz = "baz"
			end

			assert "@foo is inherited" do
				@foo == "foo"
			end

			assert "@bar is overridden" do
				@bar == "inner bar"
			end

			assert "@baz is defined only for inner" do
				@baz == "baz"
			end
		end

		teardown do
			@foo = nil # not that it'd make much sense, just to demonstrate
		end
	end

	suite "Dependencies", :requires => ['foo', 'bar'] do
		assert "Will be skipped, due to unsatisfied dependencies" do
			raise "This code therefore will never be executed"
		end
	end
end
