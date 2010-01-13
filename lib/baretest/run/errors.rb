#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Run

    # Errors runner is invoked with `-f errors` or `--format errors`.
    # This runner is specifically built to provide the most possible information about
    # errors in the suite.
    #
    module Errors # :nodoc:
      def run_all
        @depth = 0
        puts "Running all tests, reporting only errors and failures"
        start = Time.now
        super
        stop = Time.now
        printf "\Ran #{@count[:test]} tests (#{@count[:pending]} pending) in %.1fs\n" \
               "#{@count[:failure]} failures and #{@count[:error]} errors encountered.\n",
               (stop-start)
      end

      def run_test(assertion, setup)
        rv = super # run the assertion
        if rv.status == :failure then
          head    = "FAILURE in #{rv.description}"
          message = rv.reason || "no failure reason given"
          stack   = "#{rv.file}:#{rv.line}"
        elsif rv.exception then
          size    = caller.size+5
          head    = "ERROR in #{rv.description}"
          message = rv.exception.message || "no exception message given"
          stack   = rv.exception.backtrace[0..-size].join("\n  ")
        else
          return
        end

        puts head, "  "+message.gsub(/\n/, "\n  "), "  "+stack, ""
      end
    end
  end

  @format["baretest/run/errors"] = Run::Errors # register the extender
end
