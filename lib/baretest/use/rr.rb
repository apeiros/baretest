BareTest.new_component :rr do
  BareTest.require 'rr'

  BareTest::Assertion::Context.send :include, RR::Adapters::RRMethods

  handle_verification_exceptions RR::Errors::RRError do |assertion, phase, exception|
    ::BareTest::Status.new(assertion, :failure, :verify, nil, exception.message)
  end

  teardown do
    begin
      ::RR.verify
    rescue ::RR::Errors::RRError => e
      raise ::BareTest::Assertion::Failure, e.message
    else
      nil
    ensure
      RR.reset
    end
  end
end
