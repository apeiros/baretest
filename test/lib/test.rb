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
		setup do
			ENV['FORMAT'] = 'minimal'
			@test_path = File.expand_path("#{__FILE__}/../../external/bootstraptest.rb")
			@wrap_path = File.expand_path("#{__FILE__}/../../external/bootstrapwrap.rb")
			@inc_path  = File.dirname(Test.required_file)
		end

		suite "File is the program" do
			assert "Should run the suite" do
				IO.popen("ruby -I '#{@inc_path}' -rtest '#{@test_path}'") { |sio|
					sio.read
				} =~ /\ATests:    1\nSuccess:  1\nPending:  0\nFailures: 0\nErrors:   0\nTime:     [^\n]+\nStatus:   success\n\z/
			end
		end
		
		suite "File is not the program" do
			assert "Should not run the suite if the file is not the program" do
				IO.popen("ruby -I '#{@inc_path}' -rtest '#{@wrap_path}'") { |sio|
					sio.read
				} =~ /\ADone\n\z/
			end
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
