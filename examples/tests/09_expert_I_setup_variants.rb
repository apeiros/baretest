# The thing we want to test
class String
  def numeric?
    self =~ /[+-]?(?:[1-9]\d*|0)(?:\.\d+)?(?:[eE][+-]?\d+)?/
  end
end

BareTest.suite do
  suite "Variations - Notation I" do
    setup :number, '123' do |number|
      @number = '123'
    end

    setup :number, '-123' do |number|
      @number = '-123'
    end

    setup :number, '1.23' do |number|
      @number = '1.23'
    end

    exercise "->" do
    end

    verify ":number should be a numeric" do
      @number.numeric?
    end
  end

  suite "Variations - Notation II" do
    setup :number, %w[123 -123 1.23 -1.23 1e3 -1e3 1e-3 -1e-3] do |number|
      @number = number
    end

    exercise "->" do
    end

    verify ":number should be a numeric" do
      @number.numeric?
    end
  end

  suite "Variations - Notation III" do
    setup :number, {'"123"' => "123", '"1.23"' => "1.23", '"1e3"' => "1e3"} do |number|
      @number = number
    end

    exercise "" do
    end

    verify ":number should be a numeric" do
      @number.numeric?
    end
  end
end
