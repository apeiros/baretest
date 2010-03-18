BareTest.suite "Integer Division" do
  # A infer (1: int, 1.2: bigdecimal, 1.2e0: float, "string", :symbol, etc.)
  data :integer_division, :csv, <<-DATA
    @divident, @divisor, @expected_quotient
    1,         1,        1
    1,         2,        0
    2,         2,        1
  DATA

  # B, 2nd row
  data :integer_division, :csv, <<-DATA
    @divident, @divisor, @expected_quotient
    Integer,   Integer,  Integer
    1,         1,        1
    1,         2,        0
    2,         2,        1
  DATA

  # C, annotate
  data :integer_division, :csv, <<-DATA
    @divident[Integer], @divisor[Integer], @expected_quotient[Integer]
    1,                  1,                 1
    1,                  2,                 0
    2,                  2,                 1
  DATA

  setup :addition, data(:integer_division)

  exercise ":@divident divided by :@divisor" do
    @actual_quotient = @divident/@divisor
  end

  verify "returns an integer" do
    kind_of Integer, @actual_quotient
  end

  verify "equals :@expected_quotient" do
    equal @expected_quotient, @actual_quotient
  end
end

Integer Division

[ success ] 1 divided by 1 returns an integer
[ success ] 1 divided by 2 returns an integer
[ success ] 2 divided by 2 returns an integer
[ success ] 1 divided by 1 equals 1
[ success ] 1 divided by 2 equals 0
[ success ] 2 divided by 2 equals 1





BareTest.suite "Integer Division" do
  setup :addition do
    @divident, @divisor, @expected_quotient = 1, 1, 1
  end
  setup :addition do
    @divident, @divisor, @expected_quotient = 1, 2, 0
  end
  setup :addition do
    @divident, @divisor, @expected_quotient = 2, 2, 1
  end

  assert ":@divident divided by :@divisor returns an integer" do
    @actual_quotient = @divident/@divisor
    kind_of Integer, @actual_quotient
  end

  assert ":@divident divided by :@divisor equals :@expected_quotient" do
    @actual_quotient = @divident/@divisor
    equal @expected_quotient, @actual_quotient
  end
end

Integer Division

[ success ] 1 divided by 1 returns an integer
[ success ] 1 divided by 2 returns an integer
[ success ] 2 divided by 2 returns an integer
[ success ] 1 divided by 1 equals 1
[ success ] 1 divided by 2 equals 0
[ success ] 2 divided by 2 equals 1
