BareTest.new_component :rr do
  begin
    require 'rr'
  rescue LoadError
    begin
      require 'rubygems'
    rescue LoadError
    end
    require 'rr'
  end

  BareTest::Assertion::Context.send :include, RR::Adapters::RRMethods

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
