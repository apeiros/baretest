#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test
  module VERSION
    MAJOR = 1
    MINOR = 0
    TINY  = 0

    def self.to_s
      "#{MAJOR}.#{MINOR||0}.#{TINY||0}"
    end
  end
end
