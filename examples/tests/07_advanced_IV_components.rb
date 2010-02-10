# This code should be in 'baretest/use/demo_component', somewhere in rubys
# $LOAD_PATH.
module DemoComponent
  module DemoMethods
    def demo
      demo_component  = @demo_component
      @demo_component = :executed
      same(:setup, demo_component)
    end
  end
end

BareTest.new_component :demo_component do
  # Make our components' assertion helpers available in assertions
  BareTest::Assertion::Context.send :include, DemoComponent::DemoMethods

  setup do
    @demo_component = :setup
  end

  teardown do
    same(:executed, @demo_component, "@demo_component after the assertion")
  end
end


BareTest.suite do
  suite "Using DemoComponent", :use => :demo_component do
    assert "Successful assertions must use the 'demo' method" do
      demo
    end

    assert "Fails if 'demo' is not invoked, even if otherwise successful" do
      true
    end

    assert "Fails if @demo_component was changed prior to calling 'demo'" do
      @demo_component = :unexpected
      demo
    end

    assert "Fails if @demo_component was changed after to calling 'demo'" do
      demo
      @demo_component = :unexpected
      true
    end
  end
end
