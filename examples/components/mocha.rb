class User; end

BareTest.suite "Mocha", :use => :mocha do
  suite "When mocking the 'find' method on the 'User' class to return :jane" do
    setup do
      User.expects(:find).with(42).returns(:jane)
    end

    assert "Calling User.find returns :jane" do
      same :jane, User.find(42)
    end

    assert "Calling User.find will make it notice reception of that method" do
      User.find(42)
      true
    end

    assert "Fails when not calling find and asserting its reception" do
      true
    end
  end
end
