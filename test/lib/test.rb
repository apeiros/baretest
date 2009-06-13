#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



Test.define "Test" do
	suite "::extender" do
		assert "Should return a hash" do
			kind_of(Hash, Test.extender)
		end
	end

	suite "::mock_adapter" do
		assert "Should be implemented" do
			failure "mock_adapter is not yet implemented"
		end
	end

	suite "::toplevel_suite" do
		assert "Should return an instance of Test::Suite"
		assert "Should be used by Test::define"
		assert "Should be used by Test::run_if_mainfile"
		assert "Should be run by Test::run"
	end

	suite "::define" do
		assert "Should add the contained suites and asserts to Test::toplevel_suite"
	end

	suite "::run_if_mainfile", :requires => ['rbconfig', 'shellwords'] do
		setup do
			ENV['FORMAT'] = 'minimal'
			@ruby      = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name'])
			@test_path = Shellwords.escape(File.expand_path("#{__FILE__}/../../external/bootstraptest.rb"))
			@wrap_path = Shellwords.escape(File.expand_path("#{__FILE__}/../../external/bootstrapwrap.rb"))
			@inc_path  = Shellwords.escape(File.dirname(Test.required_file))
		end

		suite "File is the program" do
			assert "Should run the suite" do
				IO.popen("#{@ruby} -I#{@inc_path} -rtest #{@test_path}") { |sio|
					sio.read
				} =~ /\ATests:    1\nSuccess:  1\nPending:  0\nFailures: 0\nErrors:   0\nTime:     [^\n]+\nStatus:   success\n\z/
			end
		end
		
		suite "File is not the program" do
			assert "Should not run the suite if the file is not the program" do
				IO.popen("#{@ruby} -I#{@inc_path} -rtest #{@wrap_path}") { |sio|
					sio.read
				} =~ /\ADone\n\z/
			end
		end
	end

	suite "::run" do
		assert "Should run Test's toplevel suite"
	end

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
