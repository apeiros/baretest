# Original by dominikh
# Adapted to :use framework by apeiros

# This file provides integration with the "mocha" mocking framework.


# Load this file and get integration with the "rr" mocking framework.

BareTest.new_component :mocha do
  require 'mocha'
  
  BareTest::Assertion::Context.send :include Mocha::API
  
  teardown do
    begin
      mocha_verify
    rescue Mocha::ExpectationError => e
      @reason = e.message
      @status = :failure
    ensure
      mocha_teardown
    end
  end
end
