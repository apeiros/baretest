#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  module VERSION
    MAJOR = 0
    MINOR = 1
    TINY  = 5

    def self.to_s
      "#{MAJOR}.#{MINOR||0}.#{TINY||0}"
    end
  end
end
