#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'test/support'
require 'test/run'
require 'test/suite'
require 'test/assertion'



module Test
	@extender       = {}
	@mock_adapter   = nil
	@toplevel_suite = Suite.new

	class <<self
		# A hash of extenders (require-string => module) to be used with Test::Run.
		attr_reader :extender

		# For mock integration
		attr_reader :mock_adapter

		# The toplevel suite. That's the one run_if_mainfile and define add suites
		# and assertions to.
		attr_reader :toplevel_suite
	end

	# Adds the contained assertions and suites to the toplevel suite
	def self.define(name=nil, opts={}, &block)
		if name then
			@toplevel_suite.suite(name, opts, &block)
		elsif opts && !opts.empty?
			raise ArgumentError, "Suites with options must have names"
		else
			@toplevel_suite.instance_eval(&block)
		end
	end

	# Creates a Test::Run instance, adds the assertions and suites defined in its
	# own block to that Test::Run instance's toplevel suite and if $PROGRAM_NAME
	# (aka $0) is equal to __FILE__ (means the current file is the file directly
	# executed by ruby, and not just required/loaded/evaled by another file),
	# subsequently also runs that suite.
	def self.run_if_mainfile(name=nil, opts={}, &block)
		define(name, opts, &block)
		if caller.first[/^[^:]*/] == $0 then # if is mainfile
			run(:format => ENV['FORMAT'], :interactive => ENV['INTERACTIVE'])
		end
	end

	def self.run(opts)
		Run.new(@toplevel_suite, opts).run_all
	end

	# Skipped contains variants of Suite and Assertion.
	# See Skipped::Suite and Skipped::Assertion
	module Skipped
		# Like Test::Suite, but all Assertions are defined as Skipped::Assertion
		class Suite < ::Test::Suite
			# :nodoc:
			# All Assertions use Skipped::Assertion instead of Test::Assertion.
			def assert(description=nil, &block)
				@tests << Skipped::Assertion.new(self, description, &block)
			end

			# :nodoc:
			# All setup blocks are disabled
			def setup(&block)
				[]
			end

			# :nodoc:
			# All teardown blocks are disabled
			def teardown(&block)
				[]
			end
		end

		# Like Test::Assertion, but fakes execution and sets status always to
		# skipped.
		class Assertion < ::Test::Assertion
			def execute() @status = :skipped and self end
		end
	end
end
