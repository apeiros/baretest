require 'test/support'



module Test
	def self.run_if_mainfile(&block)
		@main_suite.instance_eval(&block)
		return unless caller.first[/^[^:]*/] == $0
		@main_suite.run('cli')
	end

	# suite actually contains all suites
	class Suite
		def initialize(ancestors=nil)
			@suite, @current_suite = {}, []
		end

		def suite(name=nil, &block)
			@current_suite << name
			@suite[@current_suite.dup] ||= []
			instance_eval(&block)
			@current_suite.pop
		end
	
		def assert(message=nil, &block)
			@suite[@current_suite] << [:assert, message, block]
		end
	
		def refute(message=nil, &block)
			@suite[@current_suite] << [:refute, message, block]
		end

		def run(runner)
			require "test/run/#{runner}"
			@count  = Hash.new(0)
			@ran    = []
			run_setup()
			run_all(@suite) do |suites|
				suites.sort_by { rand }.each do |name, tests|
					run_suite(name, tests) do # enable hooks
						tests.sort_by { rand }.each do |action, message, block|
							assertion = Assertion.new(action, message, &block)
							run_test(assertion) { |_assertion| _assertion.execute } # enable hooks
							@count[:test] += 1
							@count[assertion.status] += 1
						end
						@count[:suite] += 1
					end
				end
			end
		end

		def run_setup() end
		def run_all(suites) yield(suites) end
		def run_suite(*args) yield(*args) end
		def run_test(*args) yield(*args) end
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

		assert "Assert two randomly ordered arrays to contain the same values" do
			a = [*"A".."Z"] # an array with values from A to Z
			b = a.sort_by { rand }
			a.equal_unordered(b) # can be used with any Enumerable, uses hash-key identity
		end
	end
end
