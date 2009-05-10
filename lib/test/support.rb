module Kernel
	def raises(exception_class=StandardError)
		begin
			yield
		rescue exception_class
			true
		else
			false
		end
	rescue
		false
	end

	def within_delta(a, b, delta)
		(a-b).abs < delta
	end
	
	def equal_unordered(a,b)
    count = Hash.new(0)
    a.each { |element| count[element] += 1 }
    b.each { |element| count[element] -= 1 }
    count.all? { |key, value| value.zero? }
	end

	module_function :raises, :within_delta, :equal_unordered
end

module Enumerable
	def equal_unordered(other)
    count = Hash.new(0)
    other.each { |element| count[element] += 1 }
    each { |element| count[element] -= 1 }
    count.all? { |key, value| value.zero? }
	end
end
