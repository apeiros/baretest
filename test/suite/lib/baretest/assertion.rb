#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



BareTest.define "Test" do
  suite "Assertion" do
    suite "::new" do
      assert "Should return a ::Test::Assertion instance" do
        ::Test::Assertion.new(nil, "description") { nil }.class ==
        ::Test::Assertion
      end

      assert "Should expect exactly 2 arguments" do
        raises(ArgumentError) { ::Test::Assertion.new() } &&
        raises(ArgumentError) { ::Test::Assertion.new(nil) } &&
        raises(ArgumentError) { ::Test::Assertion.new(nil, "foo", "bar") }
      end
    end

    suite "#status" do
      assert "A new Assertion should have a status of nil" do
        ::Test::Assertion.new(nil, "description") {}.status.nil?
      end

      assert "Executing an assertion with a block that returns true should be :success" do
        assertion_success = ::Test::Assertion.new(nil, "description") { true }
        assertion_success.execute
        assertion_success.status == :success
      end

      assert "Executing an assertion with a block that returns false should be :failure" do
        assertion_success = ::Test::Assertion.new(nil, "description") { false }
        assertion_success.execute
        assertion_success.status == :failure
      end

      assert "Executing an assertion with a block that raises should be :error" do
        assertion_success = ::Test::Assertion.new(nil, "description") { raise }
        assertion_success.execute
        assertion_success.status == :error
      end

      assert "Executing an assertion without a block should be :pending" do
        assertion_success = ::Test::Assertion.new(nil, "description")
        assertion_success.execute

        same :expected => :pending, :actual => assertion_success.status
      end
    end

    suite "#exception" do
      assert "An assertion that doesn't raise should have nil as exception" do
        assertion_success = ::Test::Assertion.new(nil, "description") { true }
        assertion_success.execute
        same :expected => nil, :actual => assertion_success.exception
      end
    end

    suite "#description" do
      assert "An assertion should have a description" do
        description = "The assertion description"
        assertion   = ::Test::Assertion.new(nil, description) { true }
        same :expected => description, :actual => assertion.description
      end
    end

    suite "#suite" do
      assert "An assertion can belong to a suite" do
        suite     = ::Test::Suite.new
        assertion = ::Test::Assertion.new(suite, "") { true }
        same :expected => suite, :actual => assertion.suite
      end
    end

    suite "#block" do
      assert "An assertion can have a block" do
        block     = proc { true }
        assertion = ::Test::Assertion.new(nil, "", &block)
        same :expected => block, :actual => assertion.block
      end
    end

    suite "#setup" do
      assert "Should run all enclosing suite's setup blocks, outermost first" do
        executed  = []
        block1    = proc { executed << :block1 }
        block2    = proc { executed << :block2 }
        suite1    = ::Test::Suite.new("block1") do setup(&block1) end
        suite2    = ::Test::Suite.new("suite2", suite1) do setup(&block2) end
        assertion = ::Test::Assertion.new(suite2, "assertion")

        raises_nothing do assertion.setup end &&
        equal([:block1, :block2], executed)
      end
    end

    suite "#teardown" do
      assert "Should run all enclosing suite's teardown blocks, innermost first" do
        executed  = []
        block1    = proc { executed << :block1 }
        block2    = proc { executed << :block2 }
        suite1    = ::Test::Suite.new("block1") do teardown(&block1) end
        suite2    = ::Test::Suite.new("suite2", suite1) do teardown(&block2) end
        assertion = ::Test::Assertion.new(suite2, "assertion")

        raises_nothing do assertion.teardown end &&
        equal([:block2, :block1], executed)
      end
    end

    suite "#execute" do
      assert "Execute will run the assertion's block" do
        this      = self # needed because touch is called in the block of another assertion, so otherwise it'd be local to that assertion
        assertion = ::Test::Assertion.new(nil, "") { this.touch(:execute) }
        assertion.execute
        touched(:execute)
      end
    end

    suite "#clean_copy" do
      assert "Should return an instance of Test::Assertion" do
        kind_of(::Test::Assertion, ::Test::Assertion.new("", nil).clean_copy)
      end

      assert "Should have the same description, suite and block" do
        description = "description"
        suite       = ::Test::Suite.new
        block       = proc { true }
        assertion1  = ::Test::Assertion.new(description, suite, &block)
        assertion2  = assertion1.clean_copy

        same(assertion1.description, assertion2.description, "description") &&
        same(assertion1.suite, assertion2.suite, "suite") &&
        same(assertion1.block, assertion2.block, "block")
      end
    end

    suite "#to_s" do
      assert "Assertion should have a to_s which contains the classname and the description" do
        description  = "the description"
        assertion    = Test::Assertion.new(nil, description)
        print_string = assertion.to_s

        print_string.include?(assertion.class.name) &&
        print_string.include?(description)
      end
    end

    suite "#inspect" do
      assert "Assertion should have an inspect which contains the classname, the shifted object-id in zero-padded hex, the suite's inspect and the description's inspect" do
        suite          = Test::Suite.new
        description    = "the description"
        assertion      = Test::Assertion.new(suite, description)
        def suite.inspect; "<inspect of suite>"; end

        inspect_string = assertion.inspect

        inspect_string.include?(assertion.class.name) &&
        inspect_string.include?("%08x" % (assertion.object_id >> 1)) &&
        inspect_string.include?(suite.inspect) &&
        inspect_string.include?(description.inspect)
      end
    end
  end
end
