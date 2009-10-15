BareTest.suite "MockDemo" do
  suite "nothing happens" do
    assert "Success" do
      demo_mock(nil, nil)
    end
  end

  suite "mock fails" do
    assert "Failure" do
      demo_mock(:fail, "this is the mock failure message")
    end
  end

  suite "mock errors" do
    assert "Exception" do
      demo_mock(:raise, DemoMock::Error.new("mock errors message"))
    end
  end
end
