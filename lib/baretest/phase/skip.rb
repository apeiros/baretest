#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Phase

    # BareTest::Assertion::Skip can be raised within an assertion to indicate that the
    # assertion is to be skipped. Unlike all other exceptions, this one will not set the Assertion's
    # status to :error but to :failure. The exception's #message is used as
    # Assertion#reason.
    # Also see BareTest::Assertion::Support#skip
    #
    class Skip < Abortion
      def status
        :pending
      end
    end
  end
end
