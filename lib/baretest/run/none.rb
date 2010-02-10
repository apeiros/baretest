#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Run

    # None runner is invoked with `-f none` or `--format none`.
    # This runner produces NO output at all. You can use it if you're only
    # interested in baretests exit status.
    #
    module None # :nodoc:
    end
  end

  @format["baretest/run/none"] = Run::None # register the extender
end
