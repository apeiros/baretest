class User; end

BareTest.suite "RR", :use => :rr do
  suite "When stubbing the 'find' method on the 'User' class to return :jane" do
    setup do
      stub(User).find(42) { :jane }
    end

    assert "Spying on having received 'find' fails with no call being done" do
      received(User).find(42).call # don't forget the final '.call' here!
    end

    assert "User.find(42) returns :jane" do
      same :jane, User.find(42)
    end

    assert "User.find(123) fails as it is an unexpected method invocation" do
      User.find(123)
    end

    assert "Spying on having received 'find' succeeds with the call being done" do
      User.find(42)
      received(User).find(42).call
      true # poor, but right now you have to do that
    end
  end

  suite "When mocking the 'find' method on the 'User' class to return :jane" do
    setup do
      mock(User).find(42) { :jane }
    end

    assert "Fails when not calling find" do
      true # still fails, as the mock expectation is not satisfied
    end

    assert "User.find(42) returns :jane" do
      same :jane, User.find(42)
    end

    assert "User.find(123) fails as it is an unexpected method invocation" do
      User.find(123)
    end

    assert "User.find(42) will satisfy the mock expectation and thus succeed" do
      User.find(42)
    end
  end
end
