# To start the test definition you do `BareTest.suite do ...`, see
# BareTest::Suite::new for more
BareTest.suite do

  # The individual tests can be grouped into suites
  suite "In order to get a success" do
    exercise "Do your exercise" do
      # but since this is only an example, there's nothing here
    end

    verify "and return a trueish value (non nil/false) in verify" do
      true
    end
  end

  suite "In order to get a failure" do
    exercise "Do your exercise" do
      # but since this is only an example, there's nothing here
    end

    verify "and return a falsish value (nil/false) in verify" do
      false
    end

    verify "and invoke fail in verify" do
      fail "And provide a custom failure message"
    end
  end

  suite "In order to get a pending" do
    exercise "Have an exercise without a block"
    exercise "Have an exercise with a block" do
      # the content of this block doesn't matter
    end
    verify "and have a verify without a block"
    exercise "Have an exercise with a block and the :pending option set", :pending => true do
      # the content of this block doesn't matter
    end
    exercise "Have an exercise with a block" do
      # the content of this block doesn't matter
    end
    verify "and have a verify with the :pending option set", :pending => true do
      # the content of this block doesn't matter
    end
  end

  suite "Error" do
    assert "Uncaught exceptions are an error" do
      raise "Error!"
    end
  end
end
