#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test
	class Run
		module XML
			def run_all
				@depth = 1

				puts '<?xml version="1.0" encoding="utf-8"?>'
				puts '<tests>'
				start  = Time.now
				super
				stop   = Time.now
				status = case
					when @count[:error]   > 0 then 'error'
					when @count[:failure] > 0 then 'failure'
					when @count[:pending] > 0 then 'incomplete'
					when @count[:skipped] > 0 then 'incomplete'
					else 'success'
				end
				puts %{</tests>}
				puts %{<report>}
				puts %{\t<duration>#{stop-start}</duration>}
				@count.each { |key, value|
					puts %{\t<count type="#{key}">#{value}</count>}
				}
				puts %{</report>}
				puts %{<status>#{status}</status>}
			end

			def run_suite(suite)
				puts %{#{"\t"*@depth}<suite name="#{suite.name}">}
				@depth += 1
				super
				@depth -= 1
				puts %{#{"\t"*@depth}</suite>}
			end

			def run_test(assertion)
				rv = super
				puts %{#{"\t"*@depth}<test>}
				puts %{#{"\t"*@depth}\t<status>#{rv.status}</status>}
				puts %{#{"\t"*@depth}\t<message>#{rv.message}</message>}
				puts %{#{"\t"*@depth}</test>}
			end
		end
	end

	@extender["test/run/xml"] = Run::XML
end
