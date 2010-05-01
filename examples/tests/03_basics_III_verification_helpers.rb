BareTest.suite "Basics III - Verification helpers", :use => :basic_verifications do
  suite "Testing exceptions" do
    exercise "Calling gsub without an argument on a string" do
      "some string".gsub
    end

    verify "raises" do
      raises
    end

    then_verify "raises an ArgumentError" do
      raises ArgumentError
    end

    then_verify "raises an Argument error with the message 'wrong number of arguments (0 for 2)'" do
      raises ArgumentError, "wrong number of arguments (0 for 2)"
    end
  end

  suite "Testing floats" do
    exercise "Subtracting 0.01 from 0.18" do
      @a = 0.18 - 0.01
      @b = 0.17
    end

    verify "results in a value that is NOT equal 0.17" do
      @a != @b # floats are approximations, the result differs after a few the decimal positions
    end

    then_verify "results in a value that is close to 0.17" do
      within_delta @a, @b, 0.001 # using @a == @b would be false, because @a == 0.169... and @b == 0.170...
    end
  end

  suite "Testing unordered collections" do
    exercise "Two randomly ordered arrays to contain the same values" do
      @a = [*"A".."Z"] # an array with values from A to Z
      @b = @a.sort_by { rand }
    end

    verify "are not equal" do
      @a != @b
    end

    then_verify "are unordered_equal" do
      equal_unordered(@a, @b) # can be used with any Enumerable, uses hash-key identity
    end
  end
end
