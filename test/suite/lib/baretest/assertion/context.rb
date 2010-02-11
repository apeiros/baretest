#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



BareTest.suite "BareTest" do
  suite "Assertion" do
    suite "Context" do
      suite "::new" do
        suite "Expects 1 argument" do
          assert "Raises ArgumentError with less than 1 argument" do
            raises ArgumentError do BareTest::Assertion::Context.new end
          end

          assert "Returns a Context with 1 argument" do
            kind_of BareTest::Assertion::Context, BareTest::Assertion::Context.new(Object.new)
          end

          assert "Raises ArgumentError with more than 1 argument" do
            raises ArgumentError do BareTest::Assertion::Context.new(Object.new, Object.new) end
          end
        end
      end # ::new

      suite "#__assertion__" do
        setup do
          @assertion = Object.new
          @context   = BareTest::Assertion::Context.new(@assertion)
        end

        assert "Returns the assertion the context was constructed with" do
          same(@assertion, @context.__assertion__)
        end
      end
    end # Context
  end # Assertion
end # BareTest
