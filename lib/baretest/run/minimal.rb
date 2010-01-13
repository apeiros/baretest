#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Run

    # Minimal runner is invoked with `-f minimal` or `--format minimal`.
    # This runner is mainly written as an example. It will provide the final
    # statistics (number of tests, successes, etc.).
    #
    module Minimal # :nodoc:
      def run_all(*args)
        start  = Time.now
        super              # run all suites
        stop   = Time.now
        values = @count.values_at(:test, :success, :pending, :failure, :error)
        values.push(stop-start, global_status)
        printf "Tests:    %d\n" \
               "Success:  %d\n" \
               "Pending:  %d\n" \
               "Failures: %d\n" \
               "Errors:   %d\n" \
               "Time:     %f\n" \
               "Status:   %s\n",
               *values
      end
    end
  end

  @format["baretest/run/minimal"] = Run::Minimal # register the extender
end
