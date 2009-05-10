Bare Test
=========



Summary
-------

Bare Test is a concise testing framework that has all you need but nothing more.



Features
--------

* Strightforward and DRY assertions (just a block that should return true)
* Easy grouping of assertions
* BDD style specifications/test descriptions (NOT code), also extractable
* Uncomplicated dependency testing and skipping (TODO)
* Helpers to deal painlessly with raising, throwing, float imprecision, unordered collections etc.
* Ships with colored Shell formatter, XML- and TAP formatter (TODO: TAP)
* Simple to add new formatters (the standard formatters are only roughly 30 lines of code each)
* Teardown and Setup for suites (
* API to use it from code



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

      suite "Dependencies & Skipping" do
      	depends_on 'unavailable/library'

      	assert "This assertion is skipped, due to the unmet dependency" do
      		"This code is never evaluated"
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
    end
