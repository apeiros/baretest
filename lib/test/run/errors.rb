#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test
	class Run
		module Errors
			def run_all
				@depth = 0
				puts "Running all tests, reporting errors"
				super
				start = Time.now
				puts "\nDone, #{@count[:error]} errors encountered."
			end

			def run_suite(suite)
				return super unless suite.name
				puts "#{'  '*@depth+suite.name} (#{suite.tests.size} tests)"
				@depth += 1
				super # run the suite
				@depth -= 1
			end
			
			def run_test(assertion)
				rv          = super # run the assertion
				puts('  '*@depth+rv.message)
				if rv.exception then
					size = caller.size+5
					puts((['-'*80, rv.exception]+rv.exception.backtrace[0..-size]+['-'*80, '']).map { |l|
						('  '*(@depth+1))+l
					})
				end
			end
		end
	end

	@extender["test/run/errors"] = Run::Errors # register the extender
end
