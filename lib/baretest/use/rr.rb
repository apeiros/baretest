# Original by Tass`
# Adapted to :use framework by apeiros

BareTest.new_component :rr do
  require 'rr'

  BareTest::Assertion::Context.send :include, RR::Adapters::RRMethods

  teardown do
    begin
      ::RR.verify
    rescue ::RR::Errors => e
      @reason = e.message
      @status = :failure
    end
  end
end
