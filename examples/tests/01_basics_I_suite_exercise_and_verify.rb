# To start the test definition you do `suite do ...`, read the
# documentation on BareTest::Suite::new for more information.
suite "Basics I - Suite, Exercise and Verifications" do

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

  # All verifies following an exercise belong to that same exercise, so this
  # verify belongs to "Adding 1 and 2" as well
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

  # Whis means that this verify belongs to "Adding 2 and 5"
  verify "returns a Fixnum" do
    @actual_result.is_a?(Fixnum)
  end

  # And this verify belongs to "Adding 2 and 5" as well
  verify "returns 7" do
    @actual_result == 7
  end


  # Exercises can be grouped into suites
  # It is recommended that you group by Module/Class namespaces first, then
  # by method and last by topic.
  # Use documentation nomenclature (::name for class methods, #name for instance
  # methods)
  suite "Array" do
    suite "::new", :use => :basic_verifications do
      exercise "When invoked without arguments" do
        @array = Array.new
      end

      verify "it returns an Array" do
        kind_of Array, @array
        # To remember order: all Component::Support methods use the same order,
        # that is: expected, actual, message.
      end

      # Generally there is no guarantee on the order in which verifies are
      # executed. But using 'then_verify' you can impose order, which is useful
      # when verifications only make sense if the previous one was successful.
      #
      # This one for example only makes sense if the returned value is indeed
      # an Array
      then_verify "the returned Array is empty" do
        @array.empty?
      end
    end
  end
end
