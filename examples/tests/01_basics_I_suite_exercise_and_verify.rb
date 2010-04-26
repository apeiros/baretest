# To start the test definition you do `suite do ...`, read the
# documentation on BareTest::Suite::new for more information.
suite "Basics 01" do

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

  # A new exercise will bind all subsequent verifies to it
  exercise "Adding 2 and 5" do
    @actual_result = 2 + 5
  end

  verify "returns a Fixnum" do
    @actual_result.is_a?(Fixnum)
  end

  verify "returns 7" do
    @actual_result == 7
  end


  # The individual tests can be grouped into suites
  # It is recommended that you group by Module/Class namespaces first
  suite "Array" do

    # Then by method, using documentation nomenclature (:: for class methods,
    # # for instance methods
    suite "::new", :use => :basic_verifications do
      exercise "When invoked without arguments" do
        @array = Array.new
      end

      verify "it returns an Array" do
        kind_of Array, @array
        # To remember order: all Component::Support methods use the same order,
        # that is: expected, actual, message.
      end

      # Using 'and_then_' you can impose order, which is useful if verifications
      # only make sense if the previous one was successful
      verify "the returned Array is empty" do
        @array.empty?
      end
    end
  end
end
