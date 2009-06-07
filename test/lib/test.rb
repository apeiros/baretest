#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



Test.define "Test" do
	suite "::extender" do
	end

	suite "::mock_adapter" do
	end

	suite "::toplevel_suite" do
	end

	suite "::define" do
	end

	suite "::run_if_mainfile" do
		suite "if file is the program" do
			setup do
				@real_program_name = $PROGRAM_NAME # == $0
				@fakefile          = "fakefile"
				$PROGRAM_NAME      = @fakefile
			end
	
			teardown do
				$PROGRAM_NAME = @real_program_name
			end

			assert "Should run the suite" do
				# How to separate this definition from ordinary definitions?

				#Test.run_if_mainfile do
				#	assert "foobar" do touch(:mainfile_execution) end
				#end
	
				#touched(:mainfile_execution)
			end
		end

		assert "Should not run the suite if the file is not the program" do
			Test.run_if_mainfile do
				assert do touch(:mainfile_execution2) end
			end

			not_touched(:mainfile_execution2)
		end
	end

	suite "::run"
	suite "Skipped" do
		suite "Suite" do
			assert "assert" # should be SkippedAssertion
			assert "setup" # should never report any setup methods
			assert "teardown" # should never report any teardown methods
		end

		suite "Assertion" do
			assert "execute" # should always have status :skipped
		end
	end
end
