BareTest.new_component :basic_verifications do
  BareTest.require 'baretest/component/basic_verifications'

  setup do
    extend BareTest::Component::BasicVerifications
  end

  teardown do
    BareTest.clean_touches(self) # instance evaled, self is the context
  end
end
