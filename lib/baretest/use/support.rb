BareTest.new_component :support do
  setup do
    require 'baretest/assertion/support'
    extend BareTest::Assertion::Support
  end

  teardown do
    ::BareTest.clean_touches(self) # instance evaled, self is the assertion
  end
end
