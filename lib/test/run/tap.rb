#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test
	class Run
		module TAP
			def run_all
				puts "TAP version 13"
				count = proc { |acc,csuite| acc+csuite.tests.size+csuite.suites.inject(0, &count) }
				puts "1..#{count[0, suite]}"
				@current = 0
				super
			end

			def run_test(assertion)
				rv = super
				printf "%sok %d - %s%s\n",
					rv.status == :success ? '' : 'not ',
					@current+=1,
					rv.message,
					rv.status == :success ? '' : " # #{rv.status}"
			end
		end
	end

	@extender["test/run/tap"] = Run::TAP
end
