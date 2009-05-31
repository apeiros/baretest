#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test
	class Run
		module Spec
			def run_all
				@depth = 0
				super
			end

			def run_suite(suite)
				return super unless suite.name
				puts("\n"+'  '*@depth+suite.name)
				@depth += 1
				super
				@depth -= 1
			end
			
			def run_test(assertion)
				puts('  '*@depth+assertion.message)
			end
		end
	end

	@extender["test/run/spec"] = Run::Spec
end
