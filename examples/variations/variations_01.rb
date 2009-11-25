require 'pp'

BareTest.suite "Variations 01" do
  setup do puts "n1" end
  setup do puts "n2" end
  setup :a, "a1" do puts "a1" end
  setup :a, "a2" do puts "a2" end
  setup :b, "b1" do puts "b1" end
  setup :b, "b2" do puts "b2" end

  assert "variants, a: :a, b: :b" do
    true
  end
end