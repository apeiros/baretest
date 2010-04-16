#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Run

    # TAP runner is invoked with `-f tap` or `--format tap`.
    # TAP (Test Anything Protocol) output is intended as a universal, machine readable
    # output format of test frameworks. The are various tools that can further process
    # that information and leverage it in various ways of automation.
    # This runner currently implements the TA Protocol in version 13.
    #
    module TAP # :nodoc:
      def run_all
        puts "TAP version 13"
        count = proc { |acc,csuite|
          acc+
          csuite.assertions.size+
          csuite.suites.map { |d,suite| suite }.inject(0, &count)
        }
        puts "1..#{count[0, suite]}"
        @current = 0
        super
      end

      def run_test(assertion, setup)
        rv = super
        printf "%sok %d - %s%s\n",
          rv.status == :success ? '' : 'not ',
          @current+=1,
          assertion.description,
          rv.status == :success ? '' : " # #{rv.status}"

        rv
      end
    end
  end

  @format["baretest/run/tap"] = Run::TAP
end
