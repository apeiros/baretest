#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  module Skipped
    # Like Test::Assertion, but fakes execution and sets status always to
    # skipped.
    class Assertion < ::BareTest::Assertion
      def execute() @status = :skipped and self end
    end
  end
end
