require 'test/support'



module Test
	@extender = {}
	def self.extender() @extender end

	def self.run_if_mainfile(&block)
		(@run ||= Run.new('cli')).suite.instance_eval(&block)
		return unless caller.first[/^[^:]*/] == $0
		@run.run
	end

	class Run
		attr_reader :suite

		def initialize(runner)
			require "test/run/#{runner}"
			extend(Test.extender["test/run/#{runner}"])
			@suite = Suite.new
		end

		def run(count=Hash.new(0))
			@count = count
			run_all(@suite) do |main_suite|
				run_suite(main_suite)
			end
		end

		def run_all(suites)
			yield(suites)
		end
		def run_suite(suite)
			suite.tests.each do |test|
				run_test(test) { |assertion| assertion.execute }
				@count[:test] += 1
				@count[test.status] += 1
			end
			suite.suites.each do |suite| run_suite(suite) end
			@count[:suite] += 1
		end
		def run_test(assertion)
			yield(assertion)
		end
	end

	class Suite
		attr_reader :suites, :tests, :name

		def initialize(name=nil, parent=nil, &block)
			@name, @parent, @suites, @tests = name, parent, [], []
			instance_eval(&block) if block
		end

		def suite(name=nil, &block)
			@suites << suite = Suite.new(name, self)
			suite.instance_eval(&block)
		end

		def assert(message=nil, &block)
			@tests << Assertion.new(:assert, message, &block)
		end

		def refute(message=nil, &block)
			@tests << Assertion.new(:refute, message, &block)
		end
	end

	class Assertion
		attr_reader :status, :error, :message
		def initialize(action, message, &block)
			@status, @error, @message, @action, @block = nil, nil, (message || "No message given"), action, block
		end

		def execute
			@status = :pending
			@status = ((@action == :refute) ^ @block.call) ? :success : :failure if @block
		rescue => e
			@status = :error
			self
		else
			self
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
end
