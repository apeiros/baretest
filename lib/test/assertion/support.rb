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

			# To compare two collections (which must implement #each)
			# without considering order. E.g. two sets, or the keys of
			# two hashes.
			def equal_unordered(a,b)
				count = Hash.new(0)
				a.each { |element| count[element] += 1 }
				b.each { |element| count[element] -= 1 }
				unless count.all? { |key, value| value.zero? } then
					only_in_a = count.select { |ele, n| n > 0 }.map { |ele, n| ele }
					only_in_b = count.select { |ele, n| n < 0 }.map { |ele, n| ele }
					failure "Expected %p and %p to have the same items the same number of times, " \
									"but %p are only in a, and %p only in b.", a, b, only_in_a, only_in_b
				end
				true
			end

			# Uses equal? to test whether the objects are the same
			# same expected, actual
			# same :expected => expected, :actual => actual
			def same(*args)
				if args.size == 1 && Hash === args.first then
					expected = args.first[:expected]
					actual   = args.first[:actual]
				else
					expected, actual = *args
				end
				failure "Expected %p but got %p.", expected, actual unless expected.equal?(actual)
				true
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

			# Uses ...
			def equal(*args)
			end

			# Raises Test::Assertion::Failure and runs sprintf over message with *args
			# Particularly useful with %p and %s.
			def failure(message, *args)
				raise Test::Assertion::Failure, sprintf(message, *args)
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