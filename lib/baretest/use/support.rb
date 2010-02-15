BareTest.new_component :support do
  require 'baretest/assertion/support'

  BareTest::Assertion::Context.send :include, BareTest::Assertion::Support

  teardown do
    ::BareTest.clean_touches(self) # instance evaled, self is the assertion
  end
end
