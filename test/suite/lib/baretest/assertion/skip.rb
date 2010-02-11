#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



BareTest.suite "BareTest" do
  suite "Assertion" do
    suite "Skip" do
      assert "Can be raised" do
        raises BareTest::Assertion::Skip do
          raise BareTest::Assertion::Skip, "raised"
        end
      end
    end # Context
  end # Assertion
end # BareTest
