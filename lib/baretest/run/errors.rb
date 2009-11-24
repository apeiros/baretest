#--
# Copyright 2009 by Stefan Rusterholz.
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
        puts "Running all tests, reporting errors"
        super
        start = Time.now
        puts "\nDone, #{@count[:error]} errors encountered."
      end

      def run_suite(suite)
        return super unless suite.description
        puts "#{'  '*@depth+suite.description} (#{suite.assertions.size} tests, #{suite.skipped.size} skipped)"
        @depth += 1
        super # run the suite
        @depth -= 1
      end

      def run_test(assertion, setup)
        rv = super # run the assertion
        puts('  '*@depth+rv.description)
        if rv.exception then
          size = caller.size+5
          puts((['-'*80, rv.exception.message]+rv.exception.backtrace[0..-size]+['-'*80, '']).map { |l|
            ('  '*(@depth+1))+l
          })
        end
      end
    end
  end

  @format["baretest/run/errors"] = Run::Errors # register the extender
end
