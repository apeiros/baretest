module Test
	module Run
		module XML
			def run_setup(*args)
				super
				@depth = 1
			end

			def run_all(*args)
				puts '<?xml version="1.0" encoding="utf-8"?>'
				puts '<tests>'
				start  = Time.now
				super
				stop   = Time.now
				status = case
					when @count[:error]   > 0 then 'error'
					when @count[:failure] > 0 then 'failure'
					when @count[:pending] > 0 then 'pending'
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

			def run_suite(name, tests)
				puts %{#{"\t"*@depth}<suite name="#{name.last}">}
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

	@main_suite.extend Run::XML
end
