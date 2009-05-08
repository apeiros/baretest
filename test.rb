module Enumerable
	def equal_unordered(other)
	end
end

module Test
	Formats = {
		:pending => "\e[43m%8s \e[0m %s\n",
		:success => "\e[42m%8s \e[0m %s\n",
		:failure => "\e[41m%8s \e[0m %s\n",
		:error   => "\e[31;40;1m%8s \e[0m %s\n"  # ]]]]]]]]
	}
	class <<self
		attr_reader :count, :ran, :action
	end

	def self.init(action)
		@count  = Hash.new(0)
		@ran    = []
		@action = action
	end
	
	def self.report
		printf(Formats[@ran.last.last], @ran.last.last, @ran.last.first)
	end

	def self.run_if_mainfile(&block)
		return unless caller.first[/^[^:]*/] == $0
		Test.init(:report)
		RunTests.new.instance_eval(&block)
		printf "\n%d tests run, %d successful, %d pending, %d failures, %d errors\n",
		  *Test.count.values_at(:tests, :success, :pending, :failure, :error)
	end


	class RunTests
		def test(msg)
			Test.count[:tests] += 1
			if block_given? then
				result = yield ? :success : :failure
			else
				result = :pending
			end
		rescue
			result = :error
		ensure
			Test.ran << [msg, result]
			Test.count[result] += 1
			Test.send(Test.action)
		end
		
		def within_delta(a, b, delta)
			(a-b).abs < delta
		end
		
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
	end
end



Test.run_if_mainfile do
	test "Should be a success" do
		true
	end
	
	test "Should raise and by that be a success" do
		raises do raise "Of course it does" end
	end
	
	test "Pending"
	
	test "Failure" do
		false
	end
	
	test "Error" do
		raise "Error!"
	end
	
	test "Floats" do
		a = 0.18 - 0.01
		b = 0.17
		within_delta a, b, 0.001
	end
	
	test "Hash keys" do
		
	end
end
