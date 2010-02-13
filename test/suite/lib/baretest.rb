#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



BareTest.suite "BareTest" do
  suite "::extender" do
    assert "Should return an Array" do
      kind_of(Array, ::BareTest.extender)
    end
  end

  suite "::format" do
    assert "Should return a Hash" do
      kind_of(Hash, ::BareTest.format)
    end
  end

  suite "::toplevel_suite" do
    assert "Should return an instance of BareTest::Suite" do
      kind_of(::BareTest::Suite, ::BareTest.toplevel_suite)
    end

    assert "Should be used by BareTest::suite" do
      test = ::BareTest.clone # avoid interfering with the current run
      test.init
      suites_before = test.toplevel_suite.suites.size
      test.suite "A new suite" do end
      suites_after = test.toplevel_suite.suites.size

      equal(suites_before+1, suites_after)
    end
  end

  suite "::suite" do
    assert "Should add the contained suites and asserts to BareTest::toplevel_suite" do
      test = ::BareTest.clone # avoid interfering with the current run
      test.init
      suites_before = test.toplevel_suite.suites.size
      test.suite "A new suite" do end
      suites_after = test.toplevel_suite.suites.size

      equal(suites_before+1, suites_after)
    end
  end
end
