# To start the test definition you do `BareTest.suite do ...`, see
# BareTest::Suite::new for more
BareTest.suite do

  # The individual tests can be grouped into suites
  suite "Success" do

    # A test is defined via
    #   assert "description of what we assert" do
    #     (the assertion itself)
    #   end
    # Where the return value (and/or whether it raises or throws something)
    # defines its status
    assert "Returning a trueish value (non nil/false) is a success" do
      true
    end
  end

  suite "Failure" do
    assert "Returning a falsish value (nil/false) is a failure" do
      false
    end
  end

  suite "Pending" do
    assert "Without a block is pending"
  end

  suite "Error" do
    assert "Uncaught exceptions are an error" do
      raise "Error!"
    end
  end
end
