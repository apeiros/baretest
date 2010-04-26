BareTest.suite do
  assert "The given block raises" do
    raises do
      raise "If this raises then the assertion is a success"
    end
  end

  assert "The given block raises a specific exception" do
    raises ArgumentError do # if you want to use {} instead of do/end, you must use parens: raises(ArgumentError) { ... }
      raise ArgumentError, "If this raises then the assertion is a success"
    end
  end

  assert "Assert a float to be close to another" do
    a = 0.18 - 0.01
    b = 0.17
    within_delta a, b, 0.001 # using a == b would be false, because a == 0.169... and b == 1.70...
  end

  assert "Assert two randomly ordered arrays to contain the same values" do
    a = [*"A".."Z"] # an array with values from A to Z
    b = a.sort_by { rand }
    equal_unordered(a, b) # can be used with any Enumerable, uses hash-key identity
  end
end
