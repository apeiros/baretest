#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Run

    # Spec runner is invoked with `-f spec` or `--format spec`.
    # This runner will not actually run the tests. It only extracts the descriptions and
    # prints them. Handy if you just want an overview over what a library is supposed to do
    # and be capable of.
    #
    module Spec # :nodoc:
      def run_all
        @depth = 0
        super
      end

      def run_suite(suite)
        return super unless suite.description
        puts("\n"+'  '*@depth+suite.description)
        @depth += 1
        super
        @depth -= 1
      end

      def run_test(assertion, setup)
        puts('  '*@depth+assertion.description)
      end
    end
  end

  @format["baretest/run/spec"] = Run::Spec
end
