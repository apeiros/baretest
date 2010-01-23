BareTest.new_component :rack_test do
  begin
    require 'rubygems'
  rescue LoadError; end
  require 'rack/test'

  BareTest::Assertion::Context.send :include, Rack::Test::Methods
  BareTest::Assertion::Context.send :attr_reader, :app
end
