#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



BareTest.suite "BareTest" do
  suite "Assertion" do
    suite "::create" do
      assert "Should accept 0-3 arguments" do
        raises_nothing { ::BareTest::Suite.create() } &&
        raises_nothing { ::BareTest::Suite.create(nil) } &&
        raises_nothing { ::BareTest::Suite.create(nil, nil) } &&
        raises_nothing { ::BareTest::Suite.create(nil, nil, {}) } &&
        raises(ArgumentError) { ::BareTest::Suite.create(nil, nil, {}, nil) }
      end

      assert "Should require a single file listed in :requires option." do
        a = self # ruby1.9 fix, no longer yields self with instance_eval
        original_require = Kernel.instance_method(:require)
        file             = 'foo/bar'
        Kernel.send(:define_method, :require) do |file, *args| a.touch(file) end
        ::BareTest::Suite.create(nil, nil, :requires => file)
        Kernel.send(:define_method, :require, original_require)

        touched file
      end

      assert "Should require all files listed in :requires option." do
        a = self # ruby1.9 fix, no longer yields self with instance_eval
        original_require = Kernel.instance_method(:require)
        files            = %w[moo/bar moo/baz moo/quuz]
        Kernel.send(:define_method, :require) do |file, *args| a.touch(file) end
        ::BareTest::Suite.create(nil, nil, :requires => files)
        Kernel.send(:define_method, :require, original_require)

        files.all? { |file| touched file }
      end

      suite ":use option" do
        setup do
          a         = self # ruby1.9 fix, no longer yields self with instance_eval
          @setup    = proc { :a }
          @teardown = proc { :b }
          setup     = @setup
          teardown  = @teardown
          ::BareTest.new_component :test_component do
            a.touch :component
            setup(&setup)
            teardown(&teardown)
          end
        end

        assert "Should activate the components listed in :use option." do
          ::BareTest::Suite.create(nil, nil, :use => :test_component)
          touched :component
        end
        
        assert "Should add the setup routines"
        assert "Should add the teardown routines"

        teardown do
          ::BareTest.components.delete(:component)
        end
      end

      assert "Should return a ::BareTest::Suite instance." do
        ::BareTest::Suite.create {}.class == ::BareTest::Suite
      end

      assert "Should return a ::BareTest::Suite instance without a block." do
        ::BareTest::Suite.create.class == ::BareTest::Skipped::Suite
      end

      assert "Should return a ::BareTest::Skipped::Suite instance if a required file is not available." do
        original_require = Kernel.instance_method(:require)
        Kernel.send(:define_method, :require) do |*args| raise LoadError end # simulate that the required file was not found
        return_value = ::BareTest::Suite.create(nil, nil, :requires => 'fake')
        Kernel.send(:define_method, :require, original_require)

        return_value.class == ::BareTest::Skipped::Suite
      end
    end

    suite "::new" do
      assert "Should return a ::BareTest::Suite instance" do
        ::BareTest::Suite.new(nil, nil).class == ::BareTest::Suite
      end

      assert "Should accept 0-2 arguments" do
        raises_nothing { ::BareTest::Suite.new() } &&
        raises_nothing { ::BareTest::Suite.new(nil) } &&
        raises_nothing { ::BareTest::Suite.new(nil, nil) } &&
        raises(ArgumentError) { ::BareTest::Suite.new(nil, nil, nil) }
      end
    end

    suite "#suites" do
      assert "Should return all the suites defined in the block." do
        expected_descriptions = %w[a b c]
        suite = ::BareTest::Suite.new do
          expected_descriptions.each { |desc|
            suite desc
          }
        end
        actual_descriptions = suite.suites.map { |description, child| description }

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

    suite "#assertions" do
      assert "Should return all the suites defined in the block." do
        expected_descriptions = %w[a b c]
        suite = ::BareTest::Suite.new do
          expected_descriptions.each { |desc|
            assert desc
          }
        end
        actual_descriptions = suite.assertions.map { |child| child.description }

        equal(
          :expected => 3,
          :actual   => suite.assertions.size,
          :message  => "number of defined assertions"
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
        suite       = ::BareTest::Suite.new(description)
        equal :expected => description, :actual => suite.description, :message => 'suite description'
      end
    end

    suite "#parent" do
      assert "A suite can have a parent suite" do
        parent = ::BareTest::Suite.new
        suite  = ::BareTest::Suite.new("", parent)
        same :expected => suite.parent, :actual => parent, :message => "suite's parent"
      end
    end

    suite "#ancestors" do
      assert "A suite can have ancestors" do
        grand_parent = ::BareTest::Suite.new("first")
        parent       = ::BareTest::Suite.new("second", grand_parent)
        suite        = ::BareTest::Suite.new("third", parent)
        equal :expected => suite.ancestors, :actual => [suite, parent, grand_parent], :message => "suite's ancestors"
      end
    end

    suite "#suite" do
      assert "Should add new suites to a suite." do
        suite = ::BareTest::Suite.new
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
          :actual   => suite.suites.map { |description, child| description },
          :message  => "the descriptions"
        )
      end

      assert "Added suites should have the receiving suite as parent." do
        parent = ::BareTest::Suite.new
        parent.suite "a"
        child  = parent.suites.first.last

        same(
          :expected => parent,
          :actual   => child.parent,
          :message  => "the parent suite"
        )
      end
    end

    suite "#setup" do
      assert "Called with a block it should add a new setup block." do
        suite  = ::BareTest::Suite.new
        block  = proc {}
        before = suite.first_component_variant.dup

        suite.setup(&block)
        after  = suite.first_component_variant.dup

        equal(
          :expected => 1,
          :actual   => after.size-before.size,
          :message  => "number of new setup blocks after adding one"
        ) &&
        same(
          :expected => (after-before).first.block,
          :actual   => block,
          :message  => "the new block"
        )

      end
    end

    suite "#teardown" do
      assert "Called with a block it should add a new teardown block." do
        suite  = ::BareTest::Suite.new
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
        suite = ::BareTest::Suite.new
        equal(
          :expected => 0,
          :actual   => suite.assertions.size,
          :message  => "number of defined assertions before adding any"
        )

        suite.assert "a"
        equal(
          :expected => 1,
          :actual   => suite.assertions.size,
          :message  => "number of defined assertions after adding one"
        )

        suite.assert "b"
        equal(
          :expected => 2,
          :actual   => suite.assertions.size,
          :message  => "number of defined assertions after adding two"
        )

        equal_unordered(
          :expected => ['a', 'b'],
          :actual   => suite.assertions.map { |child| child.description },
          :message  => "the descriptions"
        )
      end

      assert "Added assertions should have the receiving suite as suite." do
        suite     = ::BareTest::Suite.new
        suite.assert "a"
        assertion = suite.assertions.first

        same(
          :expected => suite,
          :actual   => assertion.suite,
          :message  => "the suite"
        )
      end
    end

    suite "#to_s" do
      assert "Suite should have a to_s which contains the classname and the description" do
        description  = "the description"
        suite        = ::BareTest::Suite.new(description)
        print_string = suite.to_s

        print_string.include?(suite.class.name) &&
        print_string.include?(description)
      end
    end

    suite "#inspect" do
      assert "Suite should have an inspect which contains the classname, the shifted object-id in zero-padded hex and the description's inspect" do
        description    = "the description"
        suite          = ::BareTest::Suite.new(description)
        inspect_string = suite.inspect

        inspect_string.include?(suite.class.name) &&
        inspect_string.include?("%08x" % (suite.object_id >> 1)) &&
        inspect_string.include?(description.inspect)
      end
    end
  end
end
