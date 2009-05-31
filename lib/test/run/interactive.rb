#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test
	class Run
		module Interactive
			def self.extended(obj)
				obj.init do
					require "test/irb_mode"
					extend(Test::IRBMode)
				end
			end

			def run_all
				count    = proc { |acc,csuite| acc+csuite.tests.size+csuite.suites.inject(0, &count) }
				@counted = count[0, suite] # count the number of tests to run
				@depth   = 0
				@width   = (Math.log(@counted)/Math.log(10)).floor+1

				puts "Running all tests in interactive mode\n"
				$stdout.sync = true
				print_count

				super

				puts "\n\nDone"
				$stdout.sync = false
				$stdout.flush
			end

			def run_suite(suite)
				return super unless suite.name
				@depth += 1
				super
				@depth -= 1
			end

			def run_test(assertion)
				rv          = super
				print_count
				rv
			end

			def print_count
				printf "\rRan %*d of %*d assertions", @width, @count[:test], @width, @counted
			end

			def stop_irb_mode(assertion)
				puts "\n\n"
			end
		end
	end

	@extender["test/run/interactive"] = Run::Interactive # register the extender
end
