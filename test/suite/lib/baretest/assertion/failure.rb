#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



BareTest.suite "BareTest" do
  suite "Assertion" do
    suite "Failure" do
      assert "Can be raised" do
        raises BareTest::Assertion::Failure do
          raise BareTest::Assertion::Failure, "raised"
        end
      end
    end # Context
  end # Assertion
end # BareTest
