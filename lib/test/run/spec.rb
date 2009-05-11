module Test
	class Run
		module Spec
			def run_all(*args)
				@depth = 0
				super
			end

			def run_suite(suite)
				return super unless suite.name
				puts('  '*@depth+suite.name)
				@depth += 1
				super
				@depth -= 1
				puts
			end
			
			def run_test(assertion)
				puts('  '*@depth+assertion.message)
			end
		end
	end

	@extender["test/run/spec"] = Run::Spec
end
