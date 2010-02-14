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
      extend Formatter
      option_defaults :indent => "\t"
      text       "Options for 'XML' formatter:\n"
      option     :indent,  '--indent STRING',   :String, 'String to use for indenting'
      text       "\nEnvironment variables for 'XML' formatter:\n"
      env_option :indent, 'INDENT'

      def run_all
        @depth  = 1
        @indent = @options[:indent]

        puts '<?xml version="1.0" encoding="utf-8"?>',
             '<tests>'
        start  = Time.now
        super
        stop   = Time.now
        puts %{</tests>},
             %{<report>},
             %{#{@indent}<duration>#{stop-start}</duration>}
        @count.each { |key, value|
          puts %{#{@indent}<count type="#{key}">#{value}</count>}
        }
        puts %{</report>},
             %{<status>#{global_status}</status>}
      end

      def run_suite(suite)
        puts %{#{@indent*@depth}<suite description="#{suite.description}">}
        @depth += 1
        super
        @depth -= 1
        puts %{#{@indent*@depth}</suite>}
      end

      def run_test(assertion, setup)
        rv = super
        puts %{#{@indent*@depth}<test>},
             %{#{@indent*@depth}#{@indent}<file>#{assertion.file}</file>},
             %{#{@indent*@depth}#{@indent}<line>#{assertion.line}</line>},
             %{#{@indent*@depth}#{@indent}<status>#{rv.status}</status>},
             %{#{@indent*@depth}#{@indent}<description>#{assertion.description}</description>},
             %{#{@indent*@depth}</test>}
        rv
      end
    end
  end

  @format["baretest/run/xml"] = Run::XML
end
