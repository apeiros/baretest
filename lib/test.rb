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
