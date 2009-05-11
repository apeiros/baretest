Bare Test
=========



Summary
-------

Bare Test is a concise testing framework that has all you need but nothing more.




Features
--------

* Strightforward and terse assertions (just a block whose return value defines success/failure)
* Easy grouping of assertions into suites
* BDD style specifications/test descriptions (NOT code), also extractable
* Uncomplicated dependency testing and skipping (TODO: implement - might be dropped)
* Helpers to deal painlessly with raising, throwing, float imprecision, unordered collections etc.
* Ships with colored Shell formatter, XML- and TAP formatter
* Simple to add new formatters (the standard formatters are only roughly 30 lines of code each)
* Teardown and Setup for suites
* Callbacks to integrate mock libraries hazzle free
* API to use it from code
* YARD code to extract the specifications without running the code (TODO)




Example Testsuite
-----------------
    Test.run_if_mainfile do
      # assertions and refutations can be grouped in suites. They will share
      # setup and teardown
      # they don't have to be in suites, though
      suite "Success" do
        assert "An assertion returning a trueish value (non nil/false) is a success" do
          true
        end

        refute "A refutation returning a falsish value (nil/false) is a success" do
          false
        end
      end

      suite "Failure" do
        assert "An assertion returning a falsish value (nil/false) is a failure" do
          false
        end

        refute "A refutation returning a trueish value (non nil/false) is a failure" do
          true
        end
      end

      suite "Pending" do
        assert "An assertion without a block is pending"
        refute "A refutation without a block is pending"
      end

      suite "Error" do
        assert "Uncaught exceptions in an assertion are an error" do
          raise "Error!"
        end

        refute "Uncaught exceptions in a refutation are an error" do
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

        refute "@baz is only defined for subsequent nested suite" do
          @baz == "baz"
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
    end
