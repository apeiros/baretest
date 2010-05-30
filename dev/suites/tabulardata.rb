suite "Plain Ruby", :use => [:basic_verifications, :tabular_data] do
  setup.tabular_data %{
    @a | @b    | @expected_result | @expected_type
    1  | 1     | 1                | Integer
    6  | 2.0e0 | 3.0e0            | Float
    6  | 3     | 2                | Integer
    6  | 4     | 1                | Integer
  }

  exercise ":a / :b" do
    @a / @b
  end

  verify "returns an @expected_type" do
    kind_of(@expected_type)
  end

  verify "returns @expected_result" do
    returns(@expected_result)
  end
end
