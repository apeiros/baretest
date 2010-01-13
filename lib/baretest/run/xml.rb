#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Run

    # XML runner is invoked with `-f xml` or `--format xml`.
    # This runner provides xml output as a simple machine readable format.
    # The schema is relatively simple:
    #   <tests>
    #     <suite description="the suites description">
    #       <test>
    #         <file>the file the test was defined in</file>
    #         <line>the line the assertion starts on</line>
    #         <status>one of: success, pending, skipped, failure, error</status>
    #         <description>the description of the test</test>
    #       </test>
    #       ...many tests and/or suites
    #     </suite>
    #   </tests>
    #   <report>
    #     <duration>the duration in seconds as a float</duration>
    #     <count type="the counters name, see BareTest::Run#count">integer</count>
    #     ...many counts
    #   </report>
    #   <status>The final status, one of: success, incomplete, failure, error</status>
    #
    module XML # :nodoc:
      def run_all
        @depth = 1

        puts '<?xml version="1.0" encoding="utf-8"?>',
             '<tests>'
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
        puts %{</tests>},
             %{<report>},
             %{\t<duration>#{stop-start}</duration>}
        @count.each { |key, value|
          puts %{\t<count type="#{key}">#{value}</count>}
        }
        puts %{</report>},
             %{<status>#{status}</status>}
      end

      def run_suite(suite)
        puts %{#{"\t"*@depth}<suite description="#{suite.description}">}
        @depth += 1
        super
        @depth -= 1
        puts %{#{"\t"*@depth}</suite>}
      end

      def run_test(assertion, setup)
        rv = super
        puts %{#{"\t"*@depth}<test>},
             %{#{"\t"*@depth}\t<file>#{rv.file}</file>},
             %{#{"\t"*@depth}\t<line>#{rv.line}</line>},
             %{#{"\t"*@depth}\t<status>#{rv.status}</status>},
             %{#{"\t"*@depth}\t<description>#{rv.description}</description>},
             %{#{"\t"*@depth}</test>}
      end
    end
  end

  @format["baretest/run/xml"] = Run::XML
end
