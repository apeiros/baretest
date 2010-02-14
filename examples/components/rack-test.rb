MiniApp = proc { |*a| [200, {'Content-Type' => 'text/plain'}, "hello world"] }

BareTest.suite "Rack-Test", :use => :rack_test do
  setup do
    @app = MiniApp
  end

  assert "Requesting '/' is 200 OK" do
    get '/'
    last_response.ok?
  end

  assert "Requesting / gets the body 'hello world'" do
    get '/'
    equal 'hello world', last_response.body
  end
end