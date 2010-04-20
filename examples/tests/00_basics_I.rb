# To start the test definition you do `BareTest.suite do ...`, read the
# documentation on BareTest::Suite::new for more information
BareTest.suite do

  # In the exercise, you perform the behaviour you want to test
  exercise "Adding 1 and 2" do
    @actual_result = 1+2
  end

  # In subsequent verifies you verify your expectations
  verify "returns a Fixnum" do
    @actual_result.is_a?(Fixnum)
    # you could write: kind_of(@actual_result, Fixnum)
    # that would provide you better diagnostic messages in case of a failure
    # Check the various components for other helpful methods
  end

  # All verifies belong to the same exercise
  verify "returns 3" do
    @actual_result == 3
    # you could write: equal 3, @actual_result
    # that would provide you better diagnostic messages in case of a failure
    # Check the various components for other helpful methods
  end



  # The individual tests can be grouped into suites
  # It is recommended that you group by Module/Class namespaces first
  suite "Array" do

    # Then by method, using documentation nomenclature (:: for class methods,
    # # for instance methods
    suite "::new" do
      exercise "When invoked without arguments" do
        @array = Array.new
      end

      verify "it returns an Array" do
        kind_of @array, Array
        # To remember order: all Component::Support methods use the same order
        # as their ruby counterparts. It'd be @array.kind_of?(Array) ->
        # kind_of @array, Array
      end
    end

      # The setup is 
      setup do

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
    exercise "Have an exercise with a block and the :pending option set", :pending => true do
      # do nothing
    end
  end

  suite "Error" do
    assert "Uncaught exceptions are an error" do
      raise "Error!"
    end
  end
end
