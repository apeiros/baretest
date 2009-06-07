#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



Test.define "Test" do
  suite "Run" do
    #...
  end
end

__END__
		# The toplevel suite.
		attr_reader :suite
		# The initialisation blocks of extenders
		attr_reader :inits
		def initialize(suite, opts={})
			extend(Test.mock_adapter) if Test.mock_adapter
			require "test/run/#{@format}" if @format
			extend(Test.extender["test/run/#{@format}"]) if @format
			require "test/irb_mode" if @interactive
			extend(Test::IRBMode) if @interactive
			@inits.each { |init| instance_eval(&init) }
		end
		def init(&block)
		def run_all
			run_suite(@suite)
		def run_suite(suite)
			suite.tests.each do |test|
				run_test(test)
			suite.suites.each do |suite|
				run_suite(suite)
			@count[:suite] += 1
		def run_test(assertion)
			rv = assertion.execute
			@count[:test]            += 1
			@count[assertion.status] += 1
			rv
