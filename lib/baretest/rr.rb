# Load this file and get integration with the "rr" mocking framework.

require 'rr'

module RR::Adapters::RRMethods
  extend self
end

BareTest.extend RR::Adapters::RRMethods

BareTest.toplevel_suite.teardown do
  begin
    RR.verify
  rescue RR::Errors => e
    @reason = e.message
    @status = :failure
  end
end
