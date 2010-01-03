#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/assertion/failure'
require 'baretest/assertion/skip'
begin
  require 'thread'
rescue LoadError; end # no thread support in this ruby



module BareTest
  @touch = {}

  # We don't want to litter in Assertion
  # Touches are associated withx
  # Used by BareTest::Assertion::Support#touch
  def self.touch(assertion, thing=nil) # :nodoc:
    @touch[assertion] ||= Hash.new(0)
    @touch[assertion][thing] += 1
  end

  # Used by BareTest::Assertion::Support#touched
  def self.touched(assertion, thing=nil) # :nodoc:
    @touch[assertion] ||= Hash.new(0)
    @touch[assertion][thing]
  end

  # Used by BareTest::Assertion::Support
  def self.clean_touches(assertion) # :nodoc:
    @touch.delete(assertion)
  end

  class Assertion

    # BareTest::Assertion::Support is per default included into BareTest::Assertion.
    # It provides several methods to make it easier to write assertions.
    #
    module Support

      # Creates global setup and teardown callbacks that are needed by some of
      # BareTest::Assertion::Support's methods.
      #
      module SetupAndTeardown

        # Install the setup and teardown callbacks.
        def self.extended(run_obj) # :nodoc:
          run_obj.init do
            suite.teardown do
              ::BareTest.clean_touches(self) # instance evaled, self is the assertion
            end
          end
        end

        ::BareTest.extender << self
      end

      # FIXME: undocumented and untested
      # It's really ugly. You should use a mock instead.
      def yields(subject, meth, args, *expected)
        subject.__send__(meth, *args) do |*actual|
          current = expected.shift
          return false unless actual == current
        end
        return expected.empty?
      end

      # FIXME: incomplete and untested
      def throws(symbol) # :nodoc:
        begin
          passed = false
          catch(sym) {
            yield
            passed = true
            return false
          }
          passed = true
          return true
        rescue NameError => e
          return false if e.message =~ 'uncaught throw'
          raise
        rescue Exception
          passed = true
          raise
        ensure
          raise ThrewSomethingElse unless passed
        end
      rescue ThrewSomethingElse => e
        return false
      end

      # FIXME: incomplete and untested
      def throws_nothing # :nodoc:
      end

      # Will raise a Failure if the given block doesn't raise or raises a different
      # exception than the one provided
      # You can optionally give an options :with_message, which is tested with === against
      # the exception message.
      #
      # Examples:
      #   raises do raise "will work" end # => true
      #   raises SomeException do raise SomeException end # => true
      #   raises :with_message => "bar" do raise "bar" end # => true
      #   raises SomeException, :with_message => "bar"; raise SomeException, "bar" end # => true
      #   raises :with_message => /\Aknown \w+\z/; raise "known unknown" end # => true
      def raises(exception_class=StandardError, opts={})
        yield
      rescue exception_class => exception
        if opts[:with_message] && !(opts[:with_message] === exception.message) then
          failure "Expected block to raise with the message %p, but the message was %p",
                  exception.message, opts[:with_message]
        else
          true
        end
      rescue ::BareTest::Assertion::Failure, *::BareTest::Assertion::PassthroughExceptions
        ::Kernel.raise
      rescue => exception
        failure "Expected block to raise #{exception_class}, but it raised #{exception.class}."
      else
        failure "Expected block to raise #{exception_class}, but nothing was raised."
      end

      # Will raise a Failure if the given block raises.
      def raises_nothing
        yield
      rescue ::BareTest::Assertion::Failure, *::BareTest::Assertion::PassthroughExceptions
        ::Kernel.raise
      rescue Exception => exception
        failure "Expected block to raise nothing, but it raised #{exception.class}."
      else
        true
      end

      # For comparisons of Floats you shouldn't use == but
      # for example a delta comparison instead, to take care
      # of the possible rounding differences.
      def within_delta(a, b, delta)
        (a-b).abs < delta
      rescue ::BareTest::Assertion::Failure, *::BareTest::Assertion::PassthroughExceptions
        ::Kernel.raise
      rescue Exception => e
        failure "Could not compare %p with %p due to %s", a, b, e
      end

      # Use this method to test whether certain code (e.g. a callback) was reached.
      # touch marks that it was reached, #touched tests for whether it was reached.
      #
      # Example:
      #   assert "Code in a Proc object is executed when invoking #call on it." do
      #     a_proc = proc { touch :executed }
      #     a_proc.call
      #     touched(:executed)
      #   end
      def touch(thing=nil)
        ::BareTest.touch(self, thing)
      end

      # Used to verify that something was touched. You can also verify that something was touched
      # a specific amount of times.
      #
      # See #touch
      def touched(thing=nil, times=nil)
        touched_times = ::BareTest.touched(self, thing)
        if times then
          unless touched_times == times then
            if thing then
              failure "Expected the code to touch %p %s times, but did %s times.", thing, times, touched_times
            else
              failure "Expected the code to touch %s times, but did %s times.", times, touched_times
            end
          end
        elsif touched_times < 1 then
          if thing then
            failure "Expected the code to touch %p, but it was not touched.", thing
          else
            failure "Expected the code to touch, but no touch happened."
          end
        end
        true
      end

      # Used to verify that something was not touched.
      #
      # See #touch
      def not_touched(thing=nil)
        touched(thing, 0)
      end

      # Uses equal? to test whether the objects are the same
      #
      # Can be used in either of the following ways:
      #   same expected, actual
      #   same :expected => expected, :actual => actual
      def same(*args)
        expected, actual, message = extract_args(args, :expected, :actual, :message)

        unless expected.equal?(actual) then
          if message then
            failure "Expected %s to be the same (equal?) as %p but was %p.", message, expected, actual
          else
            failure "Expected %p but got %p.", expected, actual
          end
        end
        true

      rescue ::BareTest::Assertion::Failure, *::BareTest::Assertion::PassthroughExceptions
        ::Kernel.raise
      rescue Exception => e
        failure "Could not compare %p with %p due to %s", expected, actual, e
      end

      # Uses eql? to test whether the objects are equal
      #
      # Can be used in either of the following ways:
      #   equal expected, actual
      #   equal :expected => expected, :actual => actual
      def hash_key_equal(*args)
        expected, actual, message = extract_args(args, :expected, :actual, :message)

        unless expected.eql?(actual) then
          if message then
            failure "Expected %s to be hash-key equal (eql?) to %p but was %p.", message, expected, actual
          else
            failure "Expected %p but got %p.", expected, actual
          end
        end
        true

      rescue ::BareTest::Assertion::Failure, *::BareTest::Assertion::PassthroughExceptions
        ::Kernel.raise
      rescue Exception => e
        failure "Could not compare %p with %p due to %s", expected, actual, e
      end

      # Uses == to test whether the objects are equal
      #
      # Can be used in either of the following ways:
      #   equal expected, actual
      #   equal :expected => expected, :actual => actual
      def order_equal(*args)
        expected, actual, message = extract_args(args, :expected, :actual, :message)

        unless expected == actual then
          if message then
            failure "Expected %s to be order equal (==) to %p but was %p.", message, expected, actual
          else
            failure "Expected %p but got %p.", expected, actual
          end
        end
        true

      rescue ::BareTest::Assertion::Failure, *::BareTest::Assertion::PassthroughExceptions
        ::Kernel.raise
      rescue Exception => e
        failure "Could not compare %p with %p due to %s", expected, actual, e
      end
      alias equal order_equal

      # Uses === to test whether the objects are equal
      #
      # Can be used in either of the following ways:
      #   equal expected, actual
      #   equal :expected => expected, :actual => actual
      def case_equal(*args)
        expected, actual, message = extract_args(args, :expected, :actual, :message)

        unless expected === actual then
          failure_with_optional_message \
            "Expected %s to be case equal (===) to %p but was %p.",
            "Expected %p but got %p.",
            message, expected, actual
        end
        true

      rescue ::BareTest::Assertion::Failure, *::BareTest::Assertion::PassthroughExceptions
        ::Kernel.raise
      rescue Exception => e
        failure "Could not compare %p with %p due to %s", expected, actual, e
      end

      # To compare two collections (which must implement #each)
      # without considering order. E.g. two sets, or the keys of
      # two hashes.
      def equal_unordered(*args)
        expected, actual, message = extract_args(args, :expected, :actual, :message)

        count = Hash.new(0)
        expected.each { |element| count[element] += 1 }
        actual.each   { |element| count[element] -= 1 }

        unless count.all? { |key, value| value.zero? } then
          only_in_expected = count.select { |ele, n| n > 0 }.map { |ele, n| ele }
          only_in_actual   = count.select { |ele, n| n < 0 }.map { |ele, n| ele }
          if message then
            failure "Expected %s to have the same items the same number of times, " \
                    "but %p are only in expected, and %p only in actual.",
                    message, only_in_expected, only_in_actual
          else
            failure "Expected %p and %p to have the same items the same number of times, " \
                    "but %p are only in expected, and %p only in actual.",
                    expected, actual, only_in_expected, only_in_actual
          end
        end
        true

      rescue ::BareTest::Assertion::Failure, *::BareTest::Assertion::PassthroughExceptions
        ::Kernel.raise
      rescue Exception => e
        failure "Could not compare %p with %p due to %s", expected, actual, e
      end

      # Raises a Failure if the given object is not an instance of the given class
      # or a descendant thereof
      def kind_of(*args)
        expected, actual, message = extract_args(args, :expected, :actual, :message)
        unless actual.kind_of?(expected) then
          failure_with_optional_message \
            "Expected %1$s to be a kind of %3$p, but was a %4$p",
            "Expected %2$p to be a kind of %1$p, but was a %3$p",
            message, expected, actual, actual.class
        end
        true

      rescue ::BareTest::Assertion::Failure, *::BareTest::Assertion::PassthroughExceptions
        ::Kernel.raise
      rescue Exception => e
        failure "Could not test whether %p is a child of %p due to %s", actual, expected, e
      end

      # A method to make raising failures that only optionally have a message easier.
      def failure_with_optional_message(with_message, without_message, message, *args)
        if message then
          failure(with_message, message, *args)
        else
          failure(without_message, *args)
        end
      end

      # Raises Test::Assertion::Failure, which causes the Assertion to get the
      # status :failure. Runs sprintf over message with *args
      # Particularly useful with %p and %s.
      def failure(message="Assertion failed", *args)
        raise ::BareTest::Assertion::Failure, sprintf(message, *args)
      end

      # Raises Test::Assertion::Skip, which causes the Assertion to get the
      # status :skipped. Runs sprintf over message with *args
      # Particularly useful with %p and %s.
      def skip(message="Assertion was skipped", *args)
        raise ::BareTest::Assertion::Skip, sprintf(message, *args)
      end

    private
      # extract arg allows to use named or positional args
      #
      # Example:
      #   extract_args([1,2,3], :foo, :bar, :baz) # => [1,2,3]
      #   extract_args({:foo => 1,:bar => 2, :baz => 3}, :foo, :bar, :baz) # => [1,2,3]
      #
      # Usage:
      #   def foo(*args)
      #     x,y,z = extract_args(args, :x, :y, :z)
      #   end
      #   foo(1,2,3)
      #   foo(:x => 1, :y => 2, :z => 3) # equivalent to the one above
      #
      def extract_args(args, *named)
        if args.size == 1 && Hash === args.first then
          args.first.values_at(*named)
        else
          args.first(named.size)
        end
      end
    end # Support

    class Context
      include ::BareTest::Assertion::Support
    end
  end # Assertion
end # BareTest

module Enumerable

  # Part of BareTest - require 'baretest/assertion/support'
  #
  # Returns true if all elements of self occur the same amount of times in other, regardless
  # of order. Uses +eql?+ to determine equality.
  #
  # Example:
  #   [2,1,3,2].equal_unordered?([3,2,2,1]) # => true
  def equal_unordered?(other)
    count = Hash.new(0)
    other.each { |element| count[element] += 1 }
    each { |element| count[element] -= 1 }
    count.all? { |key, value| value.zero? }
  end
end
