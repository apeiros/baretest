BareTest.suite do
  suite "Setup & Teardown" do
    # All setup blocks are executed, so adding another setup block will not
    # replace an existing one. They are executed in order of definition and
    # before *each* execution of an assert.
    setup do
      @foo = "foo"
    end

    assert "@foo should be set" do
      equal("foo", @foo)
    end

    # All teardown blocks are executed, so adding another teardown block will
    # not replace an existing one. They are executed in order of definition and
    # after *each* execution of an assert.
    teardown do
      @foo = nil # setting an instance variable to nil isn't really necessary,
                 # but f.ex. closing an open file handle or similar is a good
                 # idea.
    end
  end

  suite "Nested Setup & Teardown" do
    setup do
      @outer_setup = "outer foo"
      @bar         = "outer bar"
    end

    suite "Nested suite" do
      setup do
        @inner_setup = "inner foo"
        @bar         = "inner bar"
      end

      assert "@outer_setup is inherited" do
        equal("outer foo", @outer_setup)
      end

      assert "@inner_setup is defined" do
        equal("inner foo", @inner_setup)
      end

      assert "@bar is overridden" do
        equal(@bar, "inner bar")
      end
    end

    assert "@inner_setup is not defined in outer suite" do
      !defined?(@inner_setup)
    end
  end
end
