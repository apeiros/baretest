module Test
	module Run
		module CLI
			Formats = {
				:pending => "\e[43m%s\e[0m%s %s\n",
				:success => "\e[42m%s\e[0m%s %s\n",
				:failure => "\e[41m%s\e[0m%s %s\n",
				:error   => "\e[31;40;1m%s\e[0m%s %s\n"  # ]]]]]]]] - bbedit hates open brackets...
			}

			def run_setup(*args)
				super
				@depth = 0
			end

			def run_all(*args)
				puts "Running all tests\n\n"
				start = Time.now
				super
				printf "%2$d tests run in %1$.1fs\n%3$d successful, %4$d pending, %5$d failures, %6$d errors\n",
				  Time.now-start, *@count.values_at(:test, :success, :pending, :failure, :error)
			end

			def run_suite(name, tests)
				puts "\e[m          #{'  '*@depth}#{name.join('.')} (#{tests.size} tests)"
				@depth += 1
				super
				@depth -= 1
				puts
			end
			
			def run_test(assertion)
				rv = super
				printf(Formats[rv.status], rv.status.to_s.capitalize.center(9), '  '*@depth, rv.message)
			end
		end
	end

	@main_suite.extend Run::CLI
end
