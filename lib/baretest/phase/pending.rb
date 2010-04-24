#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Phase

    # BareTest::Assertion::Pending can be raised within an assertion to indicate that the
    # assertion is not yet implemented (pending). Unlike most other exceptions, this one will not set the Assertion's
    # status to :error but to :pending. The exception's #message is used as
    # Assertion#reason.
    #
    class Pending < Abortion
      def status
        :pending
      end
    end
  end
end
