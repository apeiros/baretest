#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Command

  # The version of the 'command' library
  module VERSION

    # The major version number
    MAJOR = 0

    # The minor version number
    MINOR = 0

    # The tiny version number
    TINY  = 1

    # The version as a string
    def self.to_s
      "#{MAJOR}.#{MINOR||0}.#{TINY||0}"
    end
  end
end
