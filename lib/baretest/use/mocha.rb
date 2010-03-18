# Original by dominikh
# Adapted to :use framework by apeiros

# This file provides integration with the "mocha" mocking framework.

BareTest.new_component :mocha do
  BareTest.require 'mocha'

  BareTest::Assertion::Context.send :include, Mocha::API

  teardown do
    begin
      mocha_verify
    rescue Mocha::ExpectationError => e
      raise ::BareTest::Assertion::Failure, e.message
    ensure
      mocha_teardown
    end
  end
end
