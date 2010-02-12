#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# FIXME: These tests are actually integration tests and not properly isolated
#        (they depend on Assertion, Status and their own integration).
#        Slated to be fixed in version 0.9



BareTest.suite "BareTest" do
  suite "Assertion" do
    suite "Support" do
      suite "#yields" do
        suite "If the expected values are yielded" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do yields([1,2,3], :each, [], [1],[2],[3]) end
            @status    = @assertion.execute
          end

          assert "Succeeds" do
            same(:success, @status.status)
          end
        end

        suite "If different values than expected are yielded" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do yields([1,2,3], :each, [], [2],[4],[8]) end
            @status    = @assertion.execute
          end

          assert "Fails" do
            same(:failure, @status.status)
          end
        end
      end

      suite "#throws" do
        suite "If the expected symbol is thrown" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do
              throws :catchme do
                throw :catchme
              end
            end
            @status    = @assertion.execute
          end

          assert "Succeeds" do
            same(:success, @status.status)
          end
        end

        suite "If a different symbol than the expected is thrown" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do
              throws :catchme do
                throw :something_else
              end
            end
            @status    = @assertion.execute
          end

          assert "Fails" do
            same(:failure, @status.status)
          end

          assert "The message states what symbol was expected to be thrown and what was thrown instead" do
            equal("Expected the code to throw :catchme, but it threw :something_else instead", @status.failure_reason)
          end
        end

        suite "If nothing is thrown" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do
              throws :catchme do
                true # don't throw anything, just return
              end
            end
            @status    = @assertion.execute
          end

          assert "Fails" do
            same(:failure, @status.status)
          end

          assert "The message states what symbol was expected to be thrown and that nothing was thrown instead" do
            equal("Expected the code to throw :catchme, but nothing was thrown", @status.failure_reason)
          end
        end
      end

      suite "#raises" do
        suite "Used without an argument and a block that raises an exception" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do
              raises do
                raise "foo"
              end
            end
            @status    = @assertion.execute
          end

          assert "Succeeds" do
            same(:success, @status.status)
          end
        end

        suite "Used with an exception class as argument and a block that raises an exception of that class" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do
              raises(ArgumentError) do
                raise ArgumentError, "foo"
              end
            end
            @status    = @assertion.execute
          end

          assert "Succeeds" do
            same(:success, @status.status)
          end
        end

        suite "Used with an exception class and a message string as arguments and a block that raises an exception of that class with that message" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do
              raises(ArgumentError, "foo") do
                raise ArgumentError, "foo"
              end
            end
            @status    = @assertion.execute
          end

          assert "Succeeds" do
            same(:success, @status.status)
          end
        end

        suite "Used with an exception class and a message regex as arguments and a block that raises an exception of that class with a matching message" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do
              raises(ArgumentError, /fo[aeiou]/) do
                raise ArgumentError, "foo"
              end
            end
            @status    = @assertion.execute
          end

          assert "Succeeds" do
            same(:success, @status.status)
          end
        end

        suite "Used with an exception class as argument and a block that raises an exception that is a subclass of that class" do
          setup do
            @expected = StandardError
            @actual   = ArgumentError
            expected  = @expected
            actual    = @actual
            @assertion = BareTest::Assertion.new nil, "test" do
              raises(expected) do
                raise actual, "foo"
              end
            end
            @status    = @assertion.execute
          end

          guard "Actual exception class is a subclass of expected exception class" do
            @actual < @expected
          end

          assert "Fails" do
            same(:failure, @status.status)
          end

          assert "The message states what exception-class was expected to be raised and what was raised instead" do
            equal("Expected the code to raise #{@expected.name}, but it raised #{@actual.name} instead", @status.failure_reason)
          end
        end

        suite "Used with an exception class as argument and a block that raises an exception that is of a different class" do
          setup do
            @expected  = expected = NameError
            @actual    = actual   = ArgumentError
            @assertion = BareTest::Assertion.new nil, "test" do
              raises(expected) do
                raise actual, "foo"
              end
            end
            @status    = @assertion.execute
          end

          guard "Actual exception class is a different class than expected exception class" do
            (@actual <=> @expected).nil?
          end

          assert "Fails" do
            same(:failure, @status.status)
          end

          assert "The message states what message was expected to be raised and what was raised instead" do
            equal("Expected the code to raise #{@expected.name}, but it raised #{@actual.name} instead", @status.failure_reason)
          end
        end

        suite "Used with an exception class and a message string as arguments and a block that raises an exception of that class but with a different message" do
          setup do
            @expected_message = expected_message = "foo"
            @actual_message   = actual_message   = "bar"
            @assertion = BareTest::Assertion.new nil, "test" do
              raises(ArgumentError, expected_message) do
                raise ArgumentError, actual_message
              end
            end
            @status    = @assertion.execute
          end

          assert "Fails" do
            same(:failure, @status.status)
          end

          assert "The message states what exception-class was expected to be raised and what was raised instead" do
            equal(
              "Expected the code to raise with the message #{@expected_message.inspect}, but the message was #{@actual_message.inspect}",
              @status.failure_reason
            )
          end
        end

        suite "Used with an exception class and a message regex as arguments and a block that raises an exception of that class with a different message" do
          setup do
            @expected_message = expected_message = /fo[aeiou]/
            @actual_message   = actual_message   = "bar"
            @assertion = BareTest::Assertion.new nil, "test" do
              raises(ArgumentError, expected_message) do
                raise ArgumentError, actual_message
              end
            end
            @status    = @assertion.execute
          end

          assert "Fails" do
            same(:failure, @status.status)
          end

          assert "The message states what exception-class was expected to be raised and what was raised instead" do
            equal(
              "Expected the code to raise with the message #{@expected_message.inspect}, but the message was #{@actual_message.inspect}",
              @status.failure_reason
            )
          end
        end

        suite "Used without argument and a block that doesn't raise" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do
              raises do
                "nothing raised -> should fail"
              end
            end
            @status    = @assertion.execute
          end

          assert "Fails" do
            same(:failure, @status.status)
          end

          assert "The message states what exception-class was expected to be raised and what was raised instead" do
            equal("Expected the code to raise, but nothing was raised", @status.failure_reason)
          end
        end

        suite "Used with an exception class as argument and a block that doesn't raise" do
          setup do
            @expected  = expected = ArgumentError
            @assertion = BareTest::Assertion.new nil, "test" do
              raises(ArgumentError) do
                "nothing raised -> should fail"
              end
            end
            @status    = @assertion.execute
          end

          assert "Fails" do
            same(:failure, @status.status)
          end

          assert "The message states what exception-class was expected to be raised and that nothing was raised instead" do
            equal("Expected the code to raise ArgumentError, but nothing was raised", @status.failure_reason)
          end
        end

        assert "Should fail when the block raises an exception not derived from the provided exception-class" do
          begin
            raises(TypeError) do raise ArgumentError, "different class -> should fail" end
          rescue ::BareTest::Assertion::Failure
            true
          else
            false
          end
        end
      end # raises

      suite "#raises_nothing" do
        suite "Used with a block that doesn't raise" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do
              raises_nothing do
                "nothing raised -> should succeed"
              end
            end
            @status    = @assertion.execute
          end

          assert "Succeeds" do
            same(:success, @status.status)
          end
        end

        suite "Used with a block that raises" do
          setup do
            @assertion = BareTest::Assertion.new nil, "test" do
              raises_nothing do
                raise "Something"
              end
            end
            @status    = @assertion.execute
          end

          assert "Fails" do
            same(:failure, @status.status)
          end

          assert "The message states that it was not expected to raise anything but that something was raised" do
            equal("Expected the code to raise nothing, but it raised RuntimeError (Something)", @status.failure_reason)
          end
        end
      end

      suite "#touch/#touched" do
        suite "When you don't touch(x), touched(x) should fail" do
          assert "When you don't touch at all, touched(x) should fail" do
            raises ::BareTest::Assertion::Failure do
              touched :foo1
            end
          end

          assert "When you don't touch something else, touched(x) should fail" do
            raises ::BareTest::Assertion::Failure do
              touch :bar2
              touched :foo2
            end
          end
        end

        suite "When you touch(x), touched(x) should not fail" do
          assert "When you touch(x), touched(x) should be true" do
            touch :foo3
            touched :foo3
          end

          assert "When you touch(x) multiple times, touched(x) should be true" do
            3.times { touch :foo4 }
            touched :foo4
          end
        end

        suite "Touching in one assertion shouldn't carry over to another assertion" do
          assert "Touch x. Preparation for next assertion" do
            touch(:foo5)
          end

          assert "No touch x, touched x should raise" do
            raises ::BareTest::Assertion::Failure do touched(:foo5) end
          end
        end
      end # #touch/#touched

      suite "#within_delta" do
        assert "Should not fail when the value is within the delta" do
          within_delta(3.0, 3.01, 0.02)
        end

        assert "Should fail when the value is not within the delta" do
          raises ::BareTest::Assertion::Failure do
            within_delta(3.0, 3.03, 0.02)
          end
        end

        assert "Should fail with invalid input" do
          raises ::BareTest::Assertion::Failure do
            within_delta(nil, nil, 0.02)
          end
        end
      end # within_delta

      suite "#equal_unordered" do
        assert "Should not fail when the two arrays contain the same items the same number of times" do
          equal_unordered([1,2,3], [3,1,2])
        end

        assert "Should fail when the two arrays don't contain the same items" do
          raises ::BareTest::Assertion::Failure do
            equal_unordered([1,2,3], [5,6,1])
          end
        end

        assert "Should fail when the two arrays contain the same items a different number of times" do
          raises ::BareTest::Assertion::Failure do
            equal_unordered([1,2,3], [3,1,2,2])
          end
        end

        assert "Should fail with invalid input" do
          raises ::BareTest::Assertion::Failure do
            equal_unordered(nil, nil)
          end
        end
      end # equal_unordered

      suite "#same" do
        assert "Should not fail when the values are the same object" do
          a = "foo"
          same(a, a)
        end

        assert "Should fail when the values are not the same object" do
          raises ::BareTest::Assertion::Failure do
            same("a", "b")
          end
        end

        assert "Should fail with invalid input" do
          raises ::BareTest::Assertion::Failure do
            x = Class.new do undef equal? end # really, who does that?
            y = x.new
            equal_unordered(y, y)
          end
        end
      end # same

      suite "#order_equal" do
        assert "Should not fail when the values are equal by ==" do
          order_equal(1, 1.0)
        end

        assert "Should fail when the values are not equal by ==" do
          raises ::BareTest::Assertion::Failure do
            order_equal(1, 1.1)
          end
        end

        assert "Should fail with invalid input" do
          raises ::BareTest::Assertion::Failure do
            x = Class.new do undef == end
            y = x.new
            order_equal(y, y)
          end
        end
      end # order_equal

      suite "#hash_key_equal" do
        assert "Should not fail when the values are the same object" do
          hash_key_equal("foo", "foo")
        end

        assert "Should fail when the values are not the same object" do
          raises ::BareTest::Assertion::Failure do
            hash_key_equal("foo", "bar")
          end
        end

        assert "Should fail with invalid input" do
          raises ::BareTest::Assertion::Failure do
            x = Class.new do undef eql? end
            y = x.new
            hash_key_equal(y, y)
          end
        end
      end # hash_key_equal

      suite "#case_equal" do
        assert "Should not fail when the values are the same object" do
          case_equal(String, "foo")
        end

        assert "Should fail when the values are not the same object" do
          raises ::BareTest::Assertion::Failure do
            case_equal(String, [])
          end
        end

        assert "Should fail with invalid input" do
          raises ::BareTest::Assertion::Failure do
            x = Class.new do undef === end
            y = x.new
            case_equal(y, y)
          end
        end
      end # case_equal

      suite "#kind_of" do
        assert "Should not fail when the value is an instance of the given class" do
          kind_of(Array, [])
        end

        assert "Should not fail when the value is an instance of a subclass of the given class" do
          kind_of(Enumerable, [])
        end

        assert "Should fail when the value is not instance of the given class or subclass" do
          raises ::BareTest::Assertion::Failure do
            kind_of(String, [])
          end
        end
      end

      suite "#respond_to" do
        assert "Should not fail when the object responds to all methods required" do
          obj = Object.new
          def obj.foo; end
          def obj.bar; end
          respond_to(obj, :foo, :bar)
        end

        assert "Should fail when the object doesn't respond to all methods required" do
          raises ::BareTest::Assertion::Failure do
            obj = Object.new
            def obj.foo; end
            respond_to(obj, :foo, :bar)
          end
        end
      end

      suite "#failure_with_optional_message" do
        assert "Should raise a BareTest::Assertion::Failure" do
          raises(::BareTest::Assertion::Failure) do
            failure_with_optional_message "With %s", "Without message", "message"
          end
        end

        assert "Should use the string with message if message is given" do
          raises(::BareTest::Assertion::Failure, "With message") do
            failure_with_optional_message "With %s", "Without message", "message"
          end
        end

        assert "Should use the string without message if no message is given" do
          raises(::BareTest::Assertion::Failure, "Without message") do
            failure_with_optional_message "With %s", "Without message", nil
          end
        end
      end

      suite "#failure" do
        assert "Should raise a BareTest::Assertion::Failure" do
          raises(::BareTest::Assertion::Failure) do
            failure "Should raise that exception"
          end
        end
      end

      suite "#skip" do
        assert "Should raise a BareTest::Assertion::Skip" do
          raises(::BareTest::Assertion::Skip) do
            skip "Should raise that exception"
          end
        end
      end
    end # Support
  end # Assertion
end # BareTest
