suite "Plain Ruby", :use => :basic_verifications, :use => :tabular_data do
  setup.tabular_data %{
    @a | @b  | @result | @type
    1  | 1   | 1       | Integer
    6  | 2.0 | 3.0     | Float
    6  | 3   | 2       | Integer
    6  | 4   | 1       | Integer
  }

  exercise "@a / @b" do
    @a + @b
  end

  verify "returns an @expected_type" do
    kind_of(@type)
  end

  verify "returns @expected_result" do
    returns(@result)
  end
end