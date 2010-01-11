#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  # The version of the baretest library
  module VERSION

    # The major version number
    MAJOR = 0

    # The minor version number
    MINOR = 2

    # The tiny version number
    TINY  = 4

    # The version as a string
    def self.to_s
      "#{MAJOR}.#{MINOR||0}.#{TINY||0}"
    end
  end
end
