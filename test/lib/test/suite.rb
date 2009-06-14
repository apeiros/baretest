#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



Test.define "Test", :requires => 'test/debug' do
  suite "Assertion" do
    suite "::create" do
      assert "Should accept 0-3 arguments" do
        raises_nothing { ::Test::Suite.create() } &&
        raises_nothing { ::Test::Suite.create(nil) } &&
        raises_nothing { ::Test::Suite.create(nil, nil) } &&
        raises_nothing { ::Test::Suite.create(nil, nil, {}) } &&
        raises(ArgumentError) { ::Test::Suite.create(nil, nil, {}, nil) }
      end

      assert "Should require a single file listed in :requires option." do
        a = self # ruby1.9 fix, no longer yields self with instance_eval
        original_require = Kernel.instance_method(:require)
        file             = 'foo/bar'
        Kernel.send(:define_method, :require) do |file, *args| a.touch(file) end
        ::Test::Suite.create(nil, nil, :requires => file)
        Kernel.send(:define_method, :require, original_require)

        touched file
      end

      assert "Should require all files listed in :requires option." do
        a = self # ruby1.9 fix, no longer yields self with instance_eval
        original_require = Kernel.instance_method(:require)
        files            = %w[moo/bar moo/baz moo/quuz]
        Kernel.send(:define_method, :require) do |file, *args| a.touch(file) end
        ::Test::Suite.create(nil, nil, :requires => files)
        Kernel.send(:define_method, :require, original_require)

        files.all? { |file| touched file }
      end

      assert "Should return a ::Test::Suite instance." do
        ::Test::Suite.create {}.class == ::Test::Suite
      end

      assert "Should return a ::Test::Suite instance without a block." do
        ::Test::Suite.create.class == ::Test::Skipped::Suite
      end

      assert "Should return a ::Test::Skipped::Suite instance if a required file is not available." do
        original_require = Kernel.instance_method(:require)
        Kernel.send(:define_method, :require) do |*args| raise LoadError end # simulate that the required file was not found
        return_value = ::Test::Suite.create(nil, nil, :requires => 'fake')
        Kernel.send(:define_method, :require, original_require)

        return_value.class == ::Test::Skipped::Suite
      end
    end

    suite "::new" do
      assert "Should return a ::Test::Suite instance" do
        ::Test::Suite.new(nil, nil).class == ::Test::Suite
      end

      assert "Should accept 0-2 arguments" do
        raises_nothing { ::Test::Suite.new() } &&
        raises_nothing { ::Test::Suite.new(nil) } &&
        raises_nothing { ::Test::Suite.new(nil, nil) } &&
        raises(ArgumentError) { ::Test::Suite.new(nil, nil, nil) }
      end
    end

    suite "#suites" do
      assert "Should return all the suites defined in the block." do
        expected_descriptions = %w[a b c]
        suite = ::Test::Suite.new do
          expected_descriptions.each { |desc|
            suite desc
          }
        end
        actual_descriptions = suite.suites.map { |child| child.description }

        equal(
          :expected => 3,
          :actual   => suite.suites.size,
          :message  => "number of defined suites"
        ) &&
        equal_unordered(
          :expected => expected_descriptions,
          :actual   => actual_descriptions,
          :message  => "the descriptions"
        )
      end
    end

    suite "#tests" do
      assert "Should return all the suites defined in the block." do
        expected_descriptions = %w[a b c]
        suite = ::Test::Suite.new do
          expected_descriptions.each { |desc|
            assert desc
          }
        end
        actual_descriptions = suite.tests.map { |child| child.description }

        equal(
          :expected => 3,
          :actual   => suite.tests.size,
          :message  => "number of defined tests"
        ) &&
        equal_unordered(
          :expected => expected_descriptions,
          :actual   => actual_descriptions,
          :message  => "the descriptions"
        )
      end
    end

    suite "#description" do
      assert "A suite should have a description" do
        description = "The suite description"
        suite       = ::Test::Suite.new(description)
        equal :expected => description, :actual => suite.description, :message => 'suite description'
      end
    end

    suite "#parent" do
      assert "A suite can have a parent suite" do
        parent = ::Test::Suite.new
        suite  = ::Test::Suite.new("", parent)
        same :expected => suite.parent, :actual => parent, :message => "suite's parent"
      end
    end

    suite "#ancestors" do
      assert "A suite can have ancestors" do
        grand_parent = ::Test::Suite.new("first")
        parent       = ::Test::Suite.new("second", grand_parent)
        suite        = ::Test::Suite.new("third", parent)
        equal :expected => suite.ancestors, :actual => [suite, parent, grand_parent], :message => "suite's ancestors"
      end
    end

    suite "#suite" do
      assert "Should add new suites to a suite." do
        suite = ::Test::Suite.new
        equal(
          :expected => 0,
          :actual   => suite.suites.size,
          :message  => "number of defined suites before adding any"
        )

        suite.suite "a"
        equal(
          :expected => 1,
          :actual   => suite.suites.size,
          :message  => "number of defined suites after adding one"
        )

        suite.suite "b"
        equal(
          :expected => 2,
          :actual   => suite.suites.size,
          :message  => "number of defined suites after adding two"
        )

        equal_unordered(
          :expected => ['a', 'b'],
          :actual   => suite.suites.map { |child| child.description },
          :message  => "the descriptions"
        )
      end

      assert "Added suites should have the receiving suite as parent." do
        parent = ::Test::Suite.new
        parent.suite "a"
        child  = parent.suites.first

        same(
          :expected => parent,
          :actual   => child.parent,
          :message  => "the parent suite"
        )
      end
    end

    suite "#setup" do
      assert "Called with a block it should add a new setup block." do
        suite  = ::Test::Suite.new
        block  = proc {}
        before = suite.setup.dup

        suite.setup(&block)
        after  = suite.setup.dup

        equal(
          :expected => 1,
          :actual   => after.size-before.size,
          :message  => "number of new setup blocks after adding one"
        ) &&
        same(
          :expected => (after-before).first,
          :actual   => block,
          :message  => "the new block"
        )

      end
    end

    suite "#teardown" do
      assert "Called with a block it should add a new teardown block." do
        suite  = ::Test::Suite.new
        block  = proc {}
        before = suite.teardown.dup

        suite.teardown(&block)
        after  = suite.teardown.dup

        equal(
          :expected => 1,
          :actual   => after.size-before.size,
          :message  => "number of new teardown blocks after adding one"
        ) &&
        same(
          :expected => (after-before).first,
          :actual   => block,
          :message  => "the new block"
        )
      end
    end

    suite "#assert" do
      assert "Should add new assertions to a suite." do
        suite = ::Test::Suite.new
        equal(
          :expected => 0,
          :actual   => suite.tests.size,
          :message  => "number of defined tests before adding any"
        )

        suite.assert "a"
        equal(
          :expected => 1,
          :actual   => suite.tests.size,
          :message  => "number of defined tests after adding one"
        )

        suite.assert "b"
        equal(
          :expected => 2,
          :actual   => suite.tests.size,
          :message  => "number of defined tests after adding two"
        )

        equal_unordered(
          :expected => ['a', 'b'],
          :actual   => suite.tests.map { |child| child.description },
          :message  => "the descriptions"
        )
      end

      assert "Added tests should have the receiving suite as suite." do
        suite     = ::Test::Suite.new
        suite.assert "a"
        assertion = suite.tests.first

        same(
          :expected => suite,
          :actual   => assertion.suite,
          :message  => "the suite"
        )
      end
    end
  end
end
