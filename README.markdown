Bare Test
=========



Summary
-------

Three methods to use it, Twenty to master it, less than hundred lines of code -
yet fully featured test-framework. That is Bare Test.




Features
--------

* Strightforward and terse assertions (just a block whose return value defines success/failure)
* Easy grouping of assertions into suites
* BDD style specifications/test descriptions (NOT code), also extractable
* Uncomplicated dependency testing and skipping
* Helpers to deal painlessly with raising, throwing, float imprecision, unordered collections etc.
* Ships with colored Shell formatter, Diagnostic-, Interactive-, XML- and TAP formatter
* Trivial to add new formatters (the standard formatters are only roughly 20-50 lines of code each)
* Teardown and Setup for suites
* Callbacks to integrate mock libraries
* API to use it from code
* baretest executable to run tests on multiple files at once
* Interactive formatter - drops you into an irb session within failed assertion
  with all setup methods executed, so you can inspect interactively why it
  failed.



Executable
----------

    baretest [options] glob[, ...]

    Options:
      -f FORMATTER             use FORMATTER for output
          --formatter
      -d, --debug              set debugging flags (set $DEBUG to true)
      -v, --version            print the version and exit
      -w, --warn               turn warnings on for your script


Planned Features
----------------

* Inline tests via Module#describe (basically the same as Test::Suite#suite)
* YARD code to extract the specifications without running the code



Rejected Features
-----------------

* Diagnostics for assertions (e.g. assert_equal(:a, :b) will give you 'Expected
  :a but got :b' as diagnostic).
  They could be implemented using a Test::Failure exception that stores the
  diagnostic text and more Test::Assertion\#helper\_methods which generate them.
  However, I think that if they are needed, assertions should be broken down
  further instead.
  Also for really fixing issues, the interactive formatter should be by far
  the nicer way.
  But of course, everything is up for discussion, so bring up a strong rationale
  in favor of it, or a patch that is not too complex, and I will reconsider it.



Example Testsuite
-----------------

From examples/test.rb:

    Test.run_if_mainfile do
      # assertions and refutations can be grouped in suites. They will share
      # setup and teardown
      # they don't have to be in suites, though
      suite "Success" do
        assert "An assertion returning a trueish value (non nil/false) is a success" do
          true
        end
      end

      suite "Failure" do
        assert "An assertion returning a falsish value (nil/false) is a failure" do
          false
        end
      end

      suite "Pending" do
        assert "An assertion without a block is pending"
      end

      suite "Error" do
        assert "Uncaught exceptions in an assertion are an error" do
          raise "Error!"
        end
      end

      suite "Special assertions" do
        assert "Assert a block to raise" do
          raises do
            sleep(rand()/3+0.05)
            raise "If this raises then the assertion is a success"
          end
        end

        assert "Assert a float to be close to another" do
          a = 0.18 - 0.01
          b = 0.17
          within_delta a, b, 0.001
        end

        suite "Nested suite" do
          assert "Assert two randomly ordered arrays to contain the same values" do
            a = [*"A".."Z"] # an array with values from A to Z
            b = a.sort_by { rand }
            a.equal_unordered(b) # can be used with any Enumerable, uses hash-key identity
          end
        end
      end

      suite "Setup & Teardown" do
        setup do
          @foo = "foo"
          @bar = "bar"
        end

        assert "@foo should be set" do
          @foo == "foo"
        end

        suite "Nested suite" do
          setup do
            @bar = "inner bar"
            @baz = "baz"
          end

          assert "@foo is inherited" do
            @foo == "foo"
          end

          assert "@bar is overridden" do
            @bar == "inner bar"
          end

          assert "@baz is defined only for inner" do
            @baz == "baz"
          end
        end

        teardown do
          @foo = nil # not that it'd make much sense, just to demonstrate
        end
      end

      suite "Dependencies", :requires => ['foo', 'bar'] do
        assert "Will be skipped, due to unsatisfied dependencies" do
          raise "This code therefore will never be executed"
        end
      end
    end
