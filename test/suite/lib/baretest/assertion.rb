#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



BareTest.suite "BareTest" do
  suite "Assertion" do
    suite "::new" do
      assert "Should return a ::BareTest::Assertion instance" do
        ::BareTest::Assertion.new(nil, "description") { nil }.class ==
        ::BareTest::Assertion
      end

      assert "Should expect exactly 2 arguments" do
        raises(ArgumentError) { ::BareTest::Assertion.new() } &&
        raises(ArgumentError) { ::BareTest::Assertion.new(nil) } &&
        raises(ArgumentError) { ::BareTest::Assertion.new(nil, "foo", "bar") }
      end
    end

    suite "#status" do
      assert "A new Assertion should have a status of nil" do
        ::BareTest::Assertion.new(nil, "description") {}.status.nil?
      end

      assert "Executing an assertion with a block that returns true should be :success" do
        assertion_success = ::BareTest::Assertion.new(nil, "description") { true }
        assertion_success.execute
        assertion_success.status == :success
      end

      assert "Executing an assertion with a block that returns false should be :failure" do
        assertion_success = ::BareTest::Assertion.new(nil, "description") { false }
        assertion_success.execute
        assertion_success.status == :failure
      end

      assert "Executing an assertion with a block that raises should be :error" do
        assertion_success = ::BareTest::Assertion.new(nil, "description") { raise }
        assertion_success.execute
        assertion_success.status == :error
      end

      assert "Executing an assertion without a block should be :pending" do
        assertion_success = ::BareTest::Assertion.new(nil, "description")
        assertion_success.execute

        same :expected => :pending, :actual => assertion_success.status
      end
    end

    suite "meta information" do
      assert "An assertion should have a valid line number and file" do
        suite = ::BareTest::Suite.new
        assertion = suite.assert do true end

        assertion[0].line && assertion[0].file
      end
    end

    suite "#exception" do
      assert "An assertion that doesn't raise should have nil as exception" do
        assertion_success = ::BareTest::Assertion.new(nil, "description") { true }
        assertion_success.execute
        same :expected => nil, :actual => assertion_success.exception
      end
    end

    suite "#description" do
      assert "An assertion should have a description" do
        description = "The assertion description"
        assertion   = ::BareTest::Assertion.new(nil, description) { true }
        same :expected => description, :actual => assertion.description
      end
    end

    suite "#suite" do
      assert "An assertion can belong to a suite" do
        suite     = ::BareTest::Suite.new
        assertion = ::BareTest::Assertion.new(suite, "") { true }
        same :expected => suite, :actual => assertion.suite
      end
    end

    suite "#block" do
      assert "An assertion can have a block" do
        block     = proc { true }
        assertion = ::BareTest::Assertion.new(nil, "", &block)
        same :expected => block, :actual => assertion.block
      end
    end

    suite "#setup" do
      assert "Should run all enclosing suite's setup blocks, outermost first" do
        executed  = []
        block1    = proc { executed << :block1 }
        block2    = proc { executed << :block2 }
        suite1    = ::BareTest::Suite.new("block1") do setup(&block1) end
        suite2    = ::BareTest::Suite.new("suite2", suite1) do setup(&block2) end
        assertion = ::BareTest::Assertion.new(suite2, "assertion")

        raises_nothing do assertion.setup end &&
        equal([:block1, :block2], executed)
      end

      assert "Should fail if setup raises an exception" do
        block     = proc { raise "Some error" }
        suite     = ::BareTest::Suite.new("block") do setup(&block) end
        assertion = ::BareTest::Assertion.new(suite, "assertion") do true end

        assertion.execute

        assertion.status == :error
      end
    end

    suite "#teardown" do
      assert "Should run all enclosing suite's teardown blocks, innermost first" do
        executed  = []
        block1    = proc { executed << :block1 }
        block2    = proc { executed << :block2 }
        suite1    = ::BareTest::Suite.new("block1") do teardown(&block1) end
        suite2    = ::BareTest::Suite.new("suite2", suite1) do teardown(&block2) end
        assertion = ::BareTest::Assertion.new(suite2, "assertion")

        raises_nothing do assertion.teardown end &&
        equal([:block2, :block1], executed)
      end

      assert "Should fail if teardown raises an exception" do
        block     = proc { raise "Some error" }
        suite     = ::BareTest::Suite.new("block") do teardown(&block) end
        assertion = ::BareTest::Assertion.new(suite, "assertion") do true end

        assertion.execute

        assertion.status == :error
      end
    end

    suite "#execute" do
      assert "Execute will run the assertion's block" do
        this      = self # needed because touch is called in the block of another assertion, so otherwise it'd be local to that assertion
        assertion = ::BareTest::Assertion.new(nil, "") { this.touch(:execute) }
        assertion.execute
        touched(:execute)
      end
    end

    suite "#clean_copy" do
      assert "Should return an instance of BareTest::Assertion" do
        kind_of(::BareTest::Assertion, ::BareTest::Assertion.new("", nil).clean_copy)
      end

      assert "Should have the same description, suite and block" do
        description = "description"
        suite       = ::BareTest::Suite.new
        block       = proc { true }
        assertion1  = ::BareTest::Assertion.new(description, suite, &block)
        assertion2  = assertion1.clean_copy

        same(assertion1.description, assertion2.description, "description") &&
        same(assertion1.suite, assertion2.suite, "suite") &&
        same(assertion1.block, assertion2.block, "block")
      end
    end

    suite "#to_s" do
      assert "Assertion should have a to_s which contains the classname and the description" do
        description  = "the description"
        assertion    = ::BareTest::Assertion.new(nil, description)
        print_string = assertion.to_s

        print_string.include?(assertion.class.name) &&
        print_string.include?(description)
      end
    end

    suite "#inspect" do
      assert "Assertion should have an inspect which contains the classname, the shifted object-id in zero-padded hex, the suite's inspect and the description's inspect" do
        suite          = ::BareTest::Suite.new
        description    = "the description"
        assertion      = ::BareTest::Assertion.new(suite, description)
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
