module Test
	module Run
		module Spec
			def run_setup(*args)
				super
				@depth = 0
			end

			def run_suite(name, tests)
				puts('  '*@depth+name.last)
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

	@main_suite.extend Run::Spec
end
