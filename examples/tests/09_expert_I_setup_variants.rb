# The thing we want to test
# NOTE: you should NOT have code like this in your test suites.
# This would normally go to a helper file.
class String
  def numeric?
    !(self !~ /[+-]?(?:[1-9]\d*|0)(?:\.\d+)?(?:[eE][+-]?\d+)?/)
  end
end

suite "Expert I - Setup variants", :use => :basic_verifications do
  suite "With ID and multiple blocks" do
    setup :number, '123' do
      @number = '123'
    end

    setup :number, '-123' do
      @number = '-123'
    end

    setup :number, '1-23' do
      @number = '1.23'
    end

    exercise "@{number}.numeric?" do
      @number.numeric?
    end

    verify "returns true" do
      returns true
    end
  end



  suite "With an ID and a values array" do
    setup(:number).values %w[123 -123 1.23 -1.23 1e3 -1e3 1e-3 -1e-3] do |number|
      @number = number
    end

    exercise "@{number}.numeric?" do
      @number.numeric?
    end

    verify "returns true" do
      returns true
    end
  end



  suite "With an ID and a substitute => value hash" do
    setup(:number).values '"123"' => "123", '"1.23"' => "1.23", '"1e3"' => "1e3" do |number|
      @number = number
    end

    # @{number} uses .inspect, :{number} uses .to_s
    exercise ":{number}.numeric?" do
      @number.numeric?
    end

    verify "returns true" do
      returns true
    end
  end



  suite "Using the tabular_data component", :use => :tabular_data do
    setup.tabular_data %{
      @divident  @divisor  @expected_quotient
      1          1         1
      6          2         3
      6          3         2
      6          4         1
    }

    exercise "@divident divided by @divisor" do
      @actual_quotient = @divident/@divisor
    end

    verify "returns an Integer" do
      kind_of Integer, @actual_quotient
    end

    then_verify "equals @expected_quotient" do
      equal @expected_quotient, @actual_quotient
    end
  end



  suite "Using the tabular_data component with a separator", :use => :tabular_data do
    setup.tabular_data %{
      @divident  | @divisor  | @expected_quotient
      1          | 1         | 1
      6          | 2         | 3
      6          | 3         | 2
      6          | 4         | 1
    }

    exercise "@divident divided by @divisor" do
      @actual_quotient = @divident/@divisor
    end

    verify "returns an Integer" do
      kind_of Integer, @actual_quotient
    end

    then_verify "equals @expected_quotient" do
      equal @expected_quotient, @actual_quotient
    end
  end



  suite "Using the tabular_data component with a table-like look", :use => :tabular_data do
    setup.tabular_data %{
      #  this is a comment, so we can use it for horizontal lines
      #+------------+-----------+--------------------+
       | @divident  | @divisor  | @expected_quotient |
      #=============|===========|====================|
       | 1          | 1         | 1                  |
      #+------------+-----------+--------------------+
       | 6          | 2         | 3                  |
      #+------------+-----------+--------------------+
       | 6          | 3         | 2                  |
      #+------------+-----------+--------------------+
       | 6          | 4         | 1                  |
      #+------------+-----------+--------------------+
    }

    exercise "@divident divided by @divisor" do
      @actual_quotient = @divident/@divisor
    end

    verify "returns an Integer" do
      kind_of Integer, @actual_quotient
    end

    then_verify "equals @expected_quotient" do
      equal @expected_quotient, @actual_quotient
    end
  end
end
