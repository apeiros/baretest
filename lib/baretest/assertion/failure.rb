#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Assertion

    # BareTest::Assertion::Failure can be raised within an assertion to indicate that the
    # assertion failed. Unlike all other exceptions, this one will not set the Assertion's
    # status to :error but to :failure. The exception's #message is used as
    # Assertion#reason.
    # Take a look at the implementation of some methods of BareTest::Assertion::Support for
    # examples on how to use it.
    #
    class Failure < StandardError
    end
  end
end
