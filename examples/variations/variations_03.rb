require 'pp'

class String
  def numeric?
    self =~ /[+-]?(?:[1-9]\d*|0)(?:\.\d+)?(?:[eE][+-]?\d+)?/
  end
end

BareTest.suite do
  suite "Variations 02" do
    setup :number, {'"123"' => "123", '"1.23"' => "1.23", '"1e3"' => "1e3"} do |number|
      @number = number
    end

    assert ":number should be a numeric" do
      @number.numeric?
    end
  end
end
