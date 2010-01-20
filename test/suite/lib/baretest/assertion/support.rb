#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Assertion
    class Context
      # used here to test for failure
      def fails # :nodoc:
        failed = false
        begin
          failed = !yield
        rescue ::BareTest::Assertion::Failure
          failed = true
        end
        unless failed then
          failure "Expected the block to fail, but it returned a true value."
        end

        true
      end
    end
  end
end

BareTest.suite "BareTest" do
  suite "Assertion" do
    suite "Support" do
      suite "#raises" do
        assert "Should not fail when used without argument and the block raises an exception derived from StandardError." do
          raises do raise "foo" end
        end

        assert "Should not fail when the block raises an exception derived from the provided exception-class." do
          raises(ArgumentError) do raise ArgumentError, "foo" end
        end

        assert "Should fail when used without argument and the block doesn't raise." do
          begin
            raises do "nothing raised -> should fail" end
          rescue ::BareTest::Assertion::Failure
            true
          else
            false
          end
        end

        assert "Should fail when the block raises an exception not derived from the provided exception-class." do
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
        assert "Should not fail when the block doesn't raise." do
          raises_nothing do; end
        end

        assert "Should fail when the block raises." do
          begin
            raises_nothing do raise "anything" end
          rescue ::BareTest::Assertion::Failure
            true
          else
            false
          end
        end
      end

      suite "#touch/#touched" do
        suite "When you don't touch(x), touched(x) should fail" do
          assert "When you don't touch at all, touched(x) should fail" do
            fails do
              touched :foo1
            end
          end

          assert "When you don't touch something else, touched(x) should fail" do
            fails do
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

          assert "No touch x, touched x should raise." do
            fails do touched(:foo5) end
          end
        end
      end # #touch/#touched

      suite "#within_delta" do
        assert "Should not fail when the value is within the delta." do
          within_delta(3.0, 3.01, 0.02)
        end

        assert "Should fail when the value is not within the delta." do
          fails do
            within_delta(3.0, 3.03, 0.02)
          end
        end

        assert "Should fail with invalid input." do
          fails do
            within_delta(nil, nil, 0.02)
          end
        end
      end # within_delta

      suite "#equal_unordered" do
        assert "Should not fail when the two arrays contain the same items the same number of times." do
          equal_unordered([1,2,3], [3,1,2])
        end

        assert "Should fail when the two arrays don't contain the same items." do
          fails do
            equal_unordered([1,2,3], [5,6,1])
          end
        end

        assert "Should fail when the two arrays contain the same items a different number of times." do
          fails do
            equal_unordered([1,2,3], [3,1,2,2])
          end
        end

        assert "Should fail with invalid input." do
          fails do
            equal_unordered(nil, nil)
          end
        end
      end # equal_unordered

      suite "#same" do
        assert "Should not fail when the values are the same object." do
          a = "foo"
          same(a, a)
        end

        assert "Should fail when the values are not the same object." do
          fails do
            same("a", "b")
          end
        end

        assert "Should fail with invalid input." do
          fails do
            x = Class.new do undef equal? end # really, who does that?
            y = x.new
            equal_unordered(y, y)
          end
        end
      end # same

      suite "#order_equal" do
        assert "Should not fail when the values are equal by ==." do
          order_equal(1, 1.0)
        end

        assert "Should fail when the values are not equal by ==." do
          fails do
            order_equal(1, 1.1)
          end
        end

        assert "Should fail with invalid input." do
          fails do
            x = Class.new do undef == end
            y = x.new
            order_equal(y, y)
          end
        end
      end # order_equal

      suite "#hash_key_equal" do
        assert "Should not fail when the values are the same object." do
          hash_key_equal("foo", "foo")
        end

        assert "Should fail when the values are not the same object." do
          fails do
            hash_key_equal("foo", "bar")
          end
        end

        assert "Should fail with invalid input." do
          fails do
            x = Class.new do undef eql? end
            y = x.new
            hash_key_equal(y, y)
          end
        end
      end # hash_key_equal

      suite "#case_equal" do
        assert "Should not fail when the values are the same object." do
          case_equal(String, "foo")
        end

        assert "Should fail when the values are not the same object." do
          fails do
            case_equal(String, [])
          end
        end

        assert "Should fail with invalid input." do
          fails do
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
          fails do
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
          fails do
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
          raises(::BareTest::Assertion::Failure, :with_message => "With message") do
            failure_with_optional_message "With %s", "Without message", "message"
          end
        end

        assert "Should use the string without message if no message is given" do
          raises(::BareTest::Assertion::Failure, :with_message => "Without message") do
            failure_with_optional_message "With %s", "Without message", nil
          end
        end
      end

      suite "#failure" do
        assert "Should raise a BareTest::Assertion::Failure." do
          raises(::BareTest::Assertion::Failure) do
            failure "Should raise that exception."
          end
        end
      end

      suite "#skip" do
        assert "Should raise a BareTest::Assertion::Skip." do
          raises(::BareTest::Assertion::Skip) do
            skip "Should raise that exception."
          end
        end
      end
    end # Support
  end # Assertion
end # BareTest
