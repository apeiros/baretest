#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



BareTest.suite "BareTest" do
  suite "::extender" do
    assert "Should return an Array" do
      kind_of(Array, ::BareTest.extender)
    end
  end

  suite "::format" do
    assert "Should return a Hash" do
      kind_of(Hash, ::BareTest.format)
    end
  end

  suite "::toplevel_suite" do
    assert "Should return an instance of BareTest::Suite" do
      kind_of(::BareTest::Suite, ::BareTest.toplevel_suite)
    end

    assert "Should be used by BareTest::suite" do
      test = ::BareTest.clone # avoid interfering with the current run
      test.init
      suites_before = test.toplevel_suite.suites.size
      test.suite "A new suite" do end
      suites_after = test.toplevel_suite.suites.size

      equal(suites_before+1, suites_after)
    end

    assert "Should be used by BareTest::run_if_mainfile" do
      test = ::BareTest.clone # avoid interfering with the current run
      test.init
      suites_before = test.toplevel_suite.suites.size
      test.run_if_mainfile "A new suite" do end
      suites_after = test.toplevel_suite.suites.size

      equal(suites_before+1, suites_after)
    end

    assert "Should be run by BareTest::run" do
      this = self # needed because touch is called in the block of another assertion, so otherwise it'd be local to that assertion
      test = ::BareTest.clone # avoid interfering with the current run
      test.init
      test.suite "A new suite" do assert do this.touch(:assertion_executed) end end
      test.run

      touched(:assertion_executed)
    end
  end

  suite "::suite" do
    assert "Should add the contained suites and asserts to BareTest::toplevel_suite" do
      test = ::BareTest.clone # avoid interfering with the current run
      test.init
      suites_before = test.toplevel_suite.suites.size
      test.suite "A new suite" do end
      suites_after = test.toplevel_suite.suites.size

      equal(suites_before+1, suites_after)
    end
  end

  suite "::run_if_mainfile", :requires => ['rbconfig', 'shellwords'] do
    setup do
      ENV['FORMAT'] = 'minimal'
      @ruby      = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name'])
      @test_path = Shellwords.escape(File.expand_path("#{__FILE__}/../../../external/bootstraptest.rb"))
      @wrap_path = Shellwords.escape(File.expand_path("#{__FILE__}/../../../external/bootstrapwrap.rb"))
      @inc_path  = Shellwords.escape(File.dirname(BareTest.required_file))
    end

    suite "File is the program" do
      assert "Should run the suite" do
        IO.popen("#{@ruby} -I#{@inc_path} -rbaretest #{@test_path}") { |sio|
          sio.read
        } =~ /\ATests:    1\nSuccess:  1\nPending:  0\nFailures: 0\nErrors:   0\nTime:     [^\n]+\nStatus:   success\n\z/
      end
    end

    suite "File is not the program" do
      assert "Should not run the suite if the file is not the program" do
        IO.popen("#{@ruby} -I#{@inc_path} -rbaretest #{@wrap_path}") { |sio|
          sio.read
        } =~ /\ADone\n\z/
      end
    end
  end

  suite "::run" do
    assert "Should run BareTest's toplevel suite" do
      this = self # needed because touch is called in the block of another assertion, so otherwise it'd be local to that assertion
      test = ::BareTest.clone # avoid interfering with the current run
      test.init
      test.suite "A new suite" do assert do this.touch(:assertion_executed) end end
      test.run

      touched(:assertion_executed)
    end
  end

  suite "Skipped" do
    suite "Suite" do
      setup do
        parent = ::BareTest::Suite.new
        parent.setup do end
        parent.teardown do end
        @suite = ::BareTest::Skipped::Suite.new("None", parent)
        @suite.setup do end
        @suite.teardown do end
      end

      suite "#ancestry_setup" do
        assert "Should always be an empty array." do
          equal([], @suite.ancestry_setup)
        end
      end

      suite "#setup" do
        assert "Should always be an empty array." do
          equal([], @suite.setup)
        end
      end

      suite "#ancestry_teardown" do
        assert "Should always be an empty array." do
          equal([], @suite.ancestry_teardown)
        end
      end

      suite "#teardown" do
        assert "Should always be an empty array." do
          equal([], @suite.teardown)
        end
      end

      suite "#assert" do
        assert "Should add new skipped assertions to a suite." do
          equal(
            :expected => 0,
            :actual   => @suite.assertions.size,
            :message  => "number of defined tests before adding any"
          )

          @suite.assert "a"
          equal(
            :expected => 1,
            :actual   => @suite.skipped.size,
            :message  => "number of defined tests after adding one"
          )

          @suite.assert "b"
          equal(
            :expected => 2,
            :actual   => @suite.skipped.size,
            :message  => "number of defined tests after adding two"
          )

          equal_unordered(
            :expected => ['a', 'b'],
            :actual   => @suite.skipped.map { |child| child.description },
            :message  => "the descriptions"
          )

          @suite.skipped.all? { |test| kind_of(::BareTest::Skipped::Assertion, test) }
        end

        assert "Added tests should have the receiving suite as suite." do
          @suite.assert "a"
          assertion = @suite.skipped.first

          same(
            :expected => @suite,
            :actual   => assertion.suite,
            :message  => "the suite"
          )
        end
      end
    end

    suite "Assertion" do
      suite "#execute" do
        suite "Given a test that succeeds" do
          assert "Should have status :skipped" do
            assertion = ::BareTest::Skipped::Assertion.new(nil, "") do true end
            assertion.execute

            equal(:skipped, assertion.status)
          end
        end

        suite "Given a test that is pending" do
          assert "Should have status :skipped" do
            assertion = ::BareTest::Skipped::Assertion.new(nil, "")
            assertion.execute

            equal(:skipped, assertion.status)
          end
        end

        suite "Given a test that fails" do
          assert "Should have status :skipped" do
            assertion = ::BareTest::Skipped::Assertion.new(nil, "") do false end
            assertion.execute

            equal(:skipped, assertion.status)
          end
        end

        suite "Given a test that errors" do
          assert "Should have status :skipped" do
            assertion = ::BareTest::Skipped::Assertion.new(nil, "") do raise end
            assertion.execute

            equal(:skipped, assertion.status)
          end
        end
      end
    end
  end
end
