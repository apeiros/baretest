#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test
	class Run
		module CLI
			Formats = {
				:pending => "\e[43m%9s\e[0m  %s%s\n",
				:skipped => "\e[43m%9s\e[0m  %s%s\n",
				:success => "\e[42m%9s\e[0m  %s%s\n",
				:failure => "\e[41m%9s\e[0m  %s%s\n",
				:error   => "\e[37;40;1m%9s\e[0m  %s%s\n"  # ]]]]]]]] - bbedit hates open brackets...
			}
			FooterFormats = {
				:incomplete => "\e[43m%9s\e[0m\n",
				:success    => "\e[42m%9s\e[0m\n",
				:failure    => "\e[41m%9s\e[0m\n",
				:error      => "\e[37;40;1m%9s\e[0m\n"  # ]]]]]]]] - bbedit hates open brackets...
			}

			def run_all(*args)
				@depth = 0
				puts "Running all tests\n"
				start = Time.now
				super # run all suites
				status = case
					when @count[:error]   > 0 then :error
					when @count[:failure] > 0 then :failure
					when @count[:pending] > 0 then :incomplete
					when @count[:skipped] > 0 then :incomplete
					else :success
				end
				printf "\n%2$d tests run in %1$.1fs\n%3$d successful, %4$d pending, %5$d failures, %6$d errors\n",
				  Time.now-start, *@count.values_at(:test, :success, :pending, :failure, :error)
				print "Final status: "
				printf FooterFormats[status], status_label(status)
			end

			def run_suite(suite)
				return super unless suite.description
				#label, size = '  '*@depth+suite.description, suite.tests.size.to_s
				#printf "\n\e[1m%-*s\e[0m (%d tests)\n", 71-size.length, label, size
				puts "          \n           \e[1m#{'  '*@depth+suite.description}\e[0m (#{suite.tests.size} tests)"
				@depth += 1
				super # run the suite
				@depth -= 1
			end

			def run_test(assertion)
				rv          = super # run the assertion
				printf(Formats[rv.status], status_label(rv.status), '  '*@depth, rv.description)
				rv
			end

			def status_label(status)
				status.to_s.capitalize.center(9)
			end
		end
	end

	@extender["test/run/cli"] = Run::CLI # register the extender
end
