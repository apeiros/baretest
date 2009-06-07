#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'test/assertion/failure'



module Test
	@touch = {}
	def self.touch(thing=nil)
		@touch[Thread.current] ||= Hash.new(0)
		@touch[Thread.current][thing] += 1
	end

	def self.touched(thing=nil)
		@touch[Thread.current] ||= Hash.new(0)
		@touch[Thread.current][thing]
	end
end

module Test
	class Assertion
		module Support
			# 
			def raises(exception_class=StandardError)
				begin
					yield
				rescue exception_class
					true
				rescue => exception
					failure "Expected block to raise #{exception_class}, but it raised #{exception.class}."
				else
					failure "Expected block to raise #{exception_class}, but nothing was raised."
				end
			end

			def raises_nothing
				yield
			rescue => exception
				failure "Expected block to raise nothing, but it raised #{exception.class}."
			else
				true
			end

			# For comparisons of Floats you shouldn't use == but
			# for example a delta comparison instead, to take care
			# of the possible rounding differences.
			def within_delta(a, b, delta)
				(a-b).abs < delta
			end

			# Use this method to test whether certain code (e.g. a callback) was reached.
			# touch marks that it was reached, #touched tests for whether it was reached.
			# Example:
			#   assert "Code in a Proc object is executed when invoking #call on it." do
			#     a_proc = proc { touch :executed }
			#     a_proc.call
			#     touched(:executed)
			#   end
			def touch(thing=nil)
				::Test.touch(thing)
			end

			# See #touch
			def touched(thing=nil, times=nil)
				touched_times = ::Test.touched(thing)
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

			# See #touch
			def not_touched(thing=nil)
				touched(thing, 0)
			end

			# Uses equal? to test whether the objects are the same
			# same expected, actual
			# same :expected => expected, :actual => actual
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
			end

			# Uses eql? to test whether the objects are equal
			# equal expected, actual
			# equal :expected => expected, :actual => actual
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
			end

			# Uses == to test whether the objects are equal
			# equal expected, actual
			# equal :expected => expected, :actual => actual
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
			end
			alias equal order_equal

			# Uses === to test whether the objects are equal
			# equal expected, actual
			# equal :expected => expected, :actual => actual
			def case_equal(*args)
				expected, actual, message = extract_args(args, :expected, :actual, :message)

				unless expected === actual then
					if message then
						failure "Expected %s to be case equal (===) to %p but was %p.", message, expected, actual
					else
						failure "Expected %p but got %p.", expected, actual
					end
				end
				true
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
										"but %p are only in a, and %p only in actual.",
										message, only_in_expected, only_in_actual
					else
						failure "Expected %p and %p to have the same items the same number of times, " \
										"but %p are only in a, and %p only in actual.",
										expected, actual, only_in_expected, only_in_actual
					end
				end
				true
			end

			# Raises Test::Assertion::Failure and runs sprintf over message with *args
			# Particularly useful with %p and %s.
			def failure(message, *args)
				raise Test::Assertion::Failure, sprintf(message, *args)
			end

		private
			def extract_args(args, *named)
				if args.size == 1 && Hash === args.first then
					args.first.values_at(*named)
				else
					args.first(named.size)
				end
			end
		end # Support

		include Support
	end # Assertion
end # Test

module Enumerable
	def equal_unordered?(other)
    count = Hash.new(0)
    other.each { |element| count[element] += 1 }
    each { |element| count[element] -= 1 }
    count.all? { |key, value| value.zero? }
	end
end
