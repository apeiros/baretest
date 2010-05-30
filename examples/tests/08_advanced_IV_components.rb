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

  setup do
    extend DemoComponent::DemoMethods
    @demo_component = :setup
  end

  teardown do
    same(:executed, @demo_component, "@demo_component after the assertion")
  end
end


BareTest.suite "Advanced IV - Components", :use => :basic_verifications do
  suite "Using DemoComponent", :use => :demo_component do
    exercise "->" do
    end

    verify "Successful assertions must use the 'demo' method" do
      demo
      true
    end

    verify "Fails if 'demo' is not invoked, even if otherwise successful" do
      true
    end

    verify "Fails if @demo_component was changed prior to calling 'demo'" do
      @demo_component = :unexpected
      demo
      true
    end

    verify "Fails if @demo_component was changed after to calling 'demo'" do
      demo
      @demo_component = :unexpected
      true
    end
  end
end
