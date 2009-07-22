#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Run
    module XML
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

      def run_test(assertion)
        rv = super
        puts %{#{"\t"*@depth}<test>},
             %{#{"\t"*@depth}\t<status>#{rv.status}</status>},
             %{#{"\t"*@depth}\t<description>#{rv.description}</description>},
             %{#{"\t"*@depth}</test>}
      end
    end
  end

  @format["test/run/xml"] = Run::XML
end
