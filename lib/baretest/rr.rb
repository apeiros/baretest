# Load this file and get integration with the "rr" mocking framework.

require 'rr'

class BareTest::Assertion::Context
  include RR::Adapters::RRMethods
end

BareTest.toplevel_suite.teardown do
  begin
    RR.verify
  rescue RR::Errors => e
    @reason = e.message
    @status = :failure
  end
end
