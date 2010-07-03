BareTest.suite "Basics IV - The four classical test phases", :use => :basic_verifications do
  suite "Setup & Teardown", :requires => 'stringio' do
    setup do
      @io = StringIO.new
    end

    exercise "After writing to the IO and rewinding it" do
      @data = "hello"
      @io.write(@data)
      @io.rewind
    end

    verify "the written data can be read from it" do
      equal(@data, @io.read)
    end

    # All teardown blocks are executed, so adding another teardown block will
    # not replace an existing one. They are executed in order of definition and
    # after *each* execution of an assert.
    teardown do
      @io.close # closing a StringIO isn't really necessary,
                # but f.ex. closing an open file handle or similar is a good
                # idea.
    end
  end

  suite "Chained Setup" do
  end

  suite "Nested Setup & Teardown" do
    setup do
      @outer_setup = "outer foo"
    end

    # All setup blocks are executed, so adding another setup block will not
    # replace an existing one. They are executed in order of definition and
    # before *each* execution of an assert.
    setup do
      @bar         = "outer bar"
    end

    suite "Nested suite" do
      setup do
        @inner_setup = "inner foo"
        @bar         = "inner bar"
      end

      exercise "nothing" do
      end

      verify "@outer_setup is inherited" do
        equal("outer foo", @outer_setup)
      end

      verify "@inner_setup is defined" do
        equal("inner foo", @inner_setup)
      end

      verify "@bar is overridden" do
        equal(@bar, "inner bar")
      end
    end

    exercise "In outer suite again," do
    end

    verify "@inner_setup is not defined in outer suite" do
      !defined?(@inner_setup)
    end
  end
end
