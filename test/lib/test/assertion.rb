#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



Test.define "Test" do
	suite "Assertion" do
		suite "::new" do
			assert "Should return a ::Test::Assertion instance" do
				Test::Assertion.new(nil, "description") { nil }.class ==
				Test::Assertion
			end

			assert "Should expect exactly 2 arguments" do
				raises(ArgumentError) { Test::Assertion.new() } &&
				raises(ArgumentError) { Test::Assertion.new(nil) } &&
				raises(ArgumentError) { Test::Assertion.new(nil, "foo", "bar") }
			end
		end

		suite "#status" do
			assert "A new Assertion should have a status of nil" do
				Test::Assertion.new(nil, "description") {}.status.nil?
			end

			assert "Executing an assertion with a block that returns true should be :success" do
				assertion_success = Test::Assertion.new(nil, "description") { true }
				assertion_success.execute
				assertion_success.status == :success
			end

			assert "Executing an assertion with a block that returns false should be :failure" do
				assertion_success = Test::Assertion.new(nil, "description") { false }
				assertion_success.execute
				assertion_success.status == :failure
			end

			assert "Executing an assertion with a block that raises should be :error" do
				assertion_success = Test::Assertion.new(nil, "description") { raise }
				assertion_success.execute
				assertion_success.status == :error
			end

			assert "Executing an assertion without a block should be :pending" do
				assertion_success = Test::Assertion.new(nil, "description")
				assertion_success.execute

				same :expected => :pending, :actual => assertion_success.status
			end
		end

		suite "#exception" do
			assert "An assertion that doesn't raise should have nil as exception" do
				assertion_success = Test::Assertion.new(nil, "description") { true }
				assertion_success.execute
				same :expected => nil, :actual => assertion_success.exception
			end
		end

		suite "#description" do
			assert "An assertion should have a description" do
				description = "The assertion description"
				assertion   = Test::Assertion.new(nil, description) { true }
				same :expected => description, :actual => assertion.description
			end
		end

		suite "#suite" do
			assert "An assertion can belong to a suite" do
				suite     = Test::Suite.new
				assertion = Test::Assertion.new(suite, "") { true }
				same :expected => suite, :actual => assertion.suite
			end
		end

		suite "#block" do
			assert "An assertion can have a block" do
				block     = proc { true }
				assertion = Test::Assertion.new(nil, "", &block)
				same :expected => block, :actual => assertion.block
			end
		end

		suite "#setup" do
			assert "Setup will give all enclosing suites' setup blocks"
		end
		suite "#teardown" do
			assert "Teardown will give all enclosing suites' teardown blocks"
		end
		suite "#execute" do
			assert "Execute will run the assertion's block" do
				assertion = Test::Assertion.new(nil, "") { touch(:execute) }
				assertion.execute
				touched(:execute)
			end
		end
		suite "#clean_copy"
	end
end
