class User; end

BareTest.suite "RR", :use => :rr do
  suite "When mocking the 'find' method on the 'User' class to return :jane" do
    setup do
      mock(User).find(42) { :jane }
    end

    assert "Calling User.find returns :jane" do
      same :jane, User.find(42)
    end

    assert "Calling User.find will make it notice reception of that method" do
      User.find(42)
      received(User).find(42).call
    end

    assert "Fails when not calling find and asserting its reception" do
      #def assert_received(subject, &block)
      #block.call(received(subject)).call
      #assert_received(User) { |u| u.find(42) }
      received(User) { |subject| subject.find(42) }
    end
  end
end
