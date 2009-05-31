#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'test/debug'



module Test
	module IRBMode
		module AssertionExtensions
		end

		def self.extended(by)
			by.init do
				require 'irb'
				require 'test/debug'
				IRB.setup(nil) # must only be called once
			end
		end

		# Formatter callback.
		# Invoked once for every assertion.
		# Gets the assertion to run as single argument.
		def run_test(assertion)
			rv = super
			# drop into irb if assertion failed
			if [:failure, :error].include?(rv.status) then
				start_irb_mode(assertion)
				irb_mode_for_assertion(assertion)
				stop_irb_mode(assertion)
			end

			@count[:test]            += 1
			@count[assertion.status] += 1
			rv
		end
		
		def start_irb_mode(assertion)
			ancestry = assertion.suite.ancestors.reverse.map { |suite| suite.name }

			puts
			puts "#{assertion.status.to_s.capitalize} in #{ancestry.join(' > ')}"
			puts "  #{assertion.message}"
			super
		rescue NoMethodError # HAX, not happy about that. necessary due to order of extend
		end

		# This method is highlevel hax, try to add necessary API to
		# Test::Assertion
		def irb_mode_for_assertion(assertion)
			irb_context = assertion.clean_copy
			irb_context.setup
			@irb = IRB::Irb.new(IRB::WorkSpace.new(irb_context.send(:binding)))
			irb  = @irb # for closure
			
			# HAX - cargo cult, taken from irb.rb, not yet really understood.
			IRB.instance_eval do
				@CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC] # loads the irbrc?
				@CONF[:MAIN_CONTEXT] = irb.context # why would the main context be set here?
			end
			# /HAX

			trap("SIGINT") do
				irb.signal_handle
			end
			catch(:IRB_EXIT) do irb.eval_input end

			irb_context.teardown
		end
		
		def stop_irb_mode(assertion)
			super
		rescue NoMethodError # HAX, not happy about that. necessary due to order of extend
		end
	end
end
