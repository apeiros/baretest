module Test
	class Run
		module Interactive
			def run_all(*args)
				require 'irb'
				require 'test/debug'

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
				# drop into irb if assertion failed
				if [:failure, :error].include?(rv.status) then
					irb_mode_for_assertion(assertion)
				end
				print_count
				rv
			end

			# This method is highlevel hax, try to add necessary API to
			# Test::Assertion
			def irb_mode_for_assertion(assertion)
				puts

				context = assertion.instance_variable_get(:@suite).ancestors # HAX inner coupling!

				puts "#{assertion.status.to_s.capitalize} in " \
             "#{context.map { |suite| suite.name }.join(' > ')}"
				puts "  "+assertion.message
				puts "\nDropping into irb"

				# HAX inner coupling!
				# create a clean assertion with the failed assertion as template
				irb_context = Test::Assertion.new(
					assertion.instance_variable_get(:@suite),
					assertion.message,
					&assertion.instance_variable_get(:@block)
				)
				# run the setup methods
				irb_context.instance_eval do
					@suite.ancestors.map { |suite| suite.setup }.flatten.reverse.
					       each { |setup| instance_eval(&setup) }
				end
				# /HAX

				IRB.setup(nil)
				@irb = IRB::Irb.new(IRB::WorkSpace.new(irb_context.instance_eval { binding }))
				irb  = @irb # for closure
				IRB.instance_eval do
					@CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
					@CONF[:MAIN_CONTEXT] = irb.context
					trap("SIGINT") do
						irb.signal_handle
					end
				end
				catch(:IRB_EXIT) do irb.eval_input end

				# HAX inner coupling!
				# run the teardown methods
				irb_context.instance_eval do
					@suite.ancestors.map { |suite| suite.teardown }.flatten.
					       each { |setup| instance_eval(&setup) }
				end
				# /HAX

				puts "\nDropping out of irb\n\n"
			end

			def print_count
				printf "\rRan %*d of %*d assertions", @width, @count[:test], @width, @counted
			end
		end
	end

	@extender["test/run/interactive"] = Run::Interactive # register the extender
end
