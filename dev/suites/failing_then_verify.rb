suite "Plain Ruby", :use => [:basic_verifications, :tabular_data] do
  setup.tabular_data %{
    @a | @b    | @result | @type
    1  | 1     | 1       | Integer
    6  | 2.0f  | 3.0f    | Float
    6  | 3     | 2.0f    | Float
    6  | 4     | 1       | Integer
  }

  exercise ":a / :b" do
    @a / @b
  end

  verify "returns an :type" do
    kind_of(@type)
  end

  then_verify "returns :result" do
    returns(@result)
  end
end
