#--
# Copyright 2009-2010 by Stefan Rusterholz.
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

      assert "Should expect 2-3 arguments" do
        raises(ArgumentError) { ::BareTest::Assertion.new() } &&
        raises(ArgumentError) { ::BareTest::Assertion.new(nil) } &&
        raises(ArgumentError) { ::BareTest::Assertion.new(nil, "foo", "bar", "baz") }
      end
    end

    suite "#execute" do
      assert "Executing an assertion with a block that returns true should be :success" do
        assertion = ::BareTest::Assertion.new(nil, "description") { true }
        status    = assertion.execute
        same(:success, status.status)
      end

      assert "Executing an assertion with a block that returns false should be :failure" do
        assertion = ::BareTest::Assertion.new(nil, "description") { false }
        status    = assertion.execute
        same(:failure, status.status)
      end

      assert "Executing an assertion with a block that raises a Failure should be :failure" do
        assertion = ::BareTest::Assertion.new(nil, "description") { raise ::BareTest::Assertion::Failure, "just fail" }
        status    = assertion.execute
        same(:failure, status.status)
      end

      assert "Executing an assertion with a block that raises should be :error" do
        assertion = ::BareTest::Assertion.new(nil, "description") { raise }
        status    = assertion.execute
        same(:error, status.status)
      end

      assert "Executing an assertion without a block should be :pending" do
        assertion = ::BareTest::Assertion.new(nil, "description")
        status    = assertion.execute
        same(:pending, status.status)
      end

      assert "Executing an assertion with a block that raises a Skip should be :manually_skipped" do
        assertion = ::BareTest::Assertion.new(nil, "description") { raise ::BareTest::Assertion::Skip, "just skip" }
        status    = assertion.execute
        same(:manually_skipped, status.status)
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
        assertion = ::BareTest::Assertion.new(nil, "description") { true }
        status    = assertion.execute
        same(nil, status.exception)
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
      assert "Fails if setup raises an exception" do
        setup     = proc { raise "Some error" }
        assertion = ::BareTest::Assertion.new(nil, "assertion") do true end
        status    = assertion.execute([setup])

        same(:error, status.status, "status.status")
      end
    end

    suite "#teardown" do
      assert "Fails if teardown raises an exception" do
        teardown  = proc { raise "Some error" }
        assertion = ::BareTest::Assertion.new(nil, "assertion") do true end
        status    = assertion.execute(nil, [teardown])

        same(:error, status.status, "status.status")
      end
    end

    suite "#execute" do
      assert "Runs the assertion's block" do
        this      = self # needed because touch is called in the block of another assertion, so otherwise it'd be local to that assertion
        assertion = ::BareTest::Assertion.new(nil, "") { this.touch(:execute) }
        assertion.execute
        touched(:execute)
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
      setup do
        @suite          = ::BareTest::Suite.new
        def @suite.inspect; "<inspect of suite>"; end

        @description    = "the description"
        @assertion      = ::BareTest::Assertion.new(@suite, @description)
        @inspect_string = @assertion.inspect
      end

      assert "Should contain the classname" do
        @inspect_string.include?(@assertion.class.name)
      end

      assert "Should contain the shifted object-id in zero-padded hex" do
        @inspect_string.include?("%08x" % (@assertion.object_id >> 1))
      end

      assert "Should contain the suite's inspect" do
        @inspect_string.include?(@suite.inspect)
      end

      assert "Should contain the  description's inspect" do
        @inspect_string.include?(@description.inspect)
      end
    end
  end
end
