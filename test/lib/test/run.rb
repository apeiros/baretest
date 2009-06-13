#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



Test.define "Test" do
  suite "Run" do
    suite "::new" do
      assert "Should return an instance of Run" do
        kind_of ::Test::Run, ::Test::Run.new(::Test::Suite.new)
      end

      assert "Should accept 1-2 arguments" do
        raises(ArgumentError) do ::Test::Run.new end &&
        raises_nothing do ::Test::Run.new(::Test::Suite.new) end &&
        raises_nothing do ::Test::Run.new(::Test::Suite.new, {}) end &&
        raises(ArgumentError) do ::Test::Run.new(::Test::Suite.new, {}, nil) end
      end

      assert "Should accept an option ':format'" do
        raises_nothing do ::Test::Run.new(::Test::Suite.new, :format => 'spec') end
      end

      assert "Should use the formatter specified in the :format option" do
        run = ::Test::Run.new(::Test::Suite.new, :format => 'spec')
        kind_of(::Test::Run::Spec, run)
      end

      assert "Should accept an option ':interactive' and load irb_mode" do
        run = ::Test::Run.new(::Test::Suite.new, :interactive => true)
        kind_of(::Test::IRBMode, run)
      end
    end

    suite "#suite" do
      assert "Should return the suite the instance was initialized with" do
        suite = ::Test::Suite.new
        run   = ::Test::Run.new(suite)

        same(suite, run.suite)
      end
    end

    suite "#inits" do
      setup do
        @executed    = []
        executed     = @executed # for closure
        @init_blocks = [
          proc { executed << :block1 },
          proc { executed << :block2 }
        ]
        init_blocks  = @init_blocks # for closure
        @extender    = Module.new do |m|
          (class <<m;self;end).send(:define_method, :extended) do |by|
            init_blocks.each { |init_block|
              by.init(&init_block)
            }
          end
        end
        $LOADED_FEATURES << 'test/run/test_init.rb' unless $LOADED_FEATURES.include?('test/run/test_init.rb') # suppress require
        ::Test.extender['test/run/test_init'] = @extender # provide the module as formatter
      end

      assert "Should return the array with blocks called at the end of initialize" do
        run = ::Test::Run.new(::Test::Suite.new, :format => 'test_init')
        equal(@init_blocks, run.inits)
      end

      assert "Should run the blocks at the end of initialize" do
        run = ::Test::Run.new(::Test::Suite.new, :format => 'test_init')
        equal([:block1, :block2], @executed)
      end
    end

    suite "#run_all" do
      assert "Invokes #run_suite with every suite in the Run instance's toplevel suite"
      assert "Invokes #run_test with every suite in the Run instance's toplevel suite"
    end

    suite "#run_suite" do
      assert "Invokes #run_suite with every suite in the given suite"
      assert "Invokes #run_test with every suite in the given suite"
      assert "Increments the counter ':suite' at the end"
    end

    suite "#run_test" do
      assert "Runs the given test"
      assert "Increments the counter ':test' at the end"

      suite "The given test was a success" do
        assert "Increments the counter ':success' at the end"
      end

      suite "The given test was pending" do
        assert "Increments the counter ':pending' at the end"
      end

      suite "The given test was skipped" do
        assert "Increments the counter ':skipped' at the end"
      end

      suite "The given test was failure" do
        assert "Increments the counter ':failure' at the end"
      end

      suite "The given test was error" do
        assert "Increments the counter ':error' at the end"
      end
    end
  end
end

__END__
		# The toplevel suite.
		attr_reader :suite
		# The initialisation blocks of extenders
		attr_reader :inits
		def initialize(suite, opts={})
			extend(Test.mock_adapter) if Test.mock_adapter
			require "test/run/#{@format}" if @format
			extend(Test.extender["test/run/#{@format}"]) if @format
			require "test/irb_mode" if @interactive
			extend(Test::IRBMode) if @interactive
			@inits.each { |init| instance_eval(&init) }
		end
		def init(&block)
		def run_all
			run_suite(@suite)
		def run_suite(suite)
			suite.tests.each do |test|
				run_test(test)
			suite.suites.each do |suite|
				run_suite(suite)
			@count[:suite] += 1
		def run_test(assertion)
			rv = assertion.execute
			@count[:test]            += 1
			@count[assertion.status] += 1
			rv
