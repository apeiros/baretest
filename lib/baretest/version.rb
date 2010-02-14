#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  # The version of the baretest library
  module VERSION

    # The major version number
    MAJOR      = 0

    # The minor version number
    MINOR      = 4

    # The tiny version number
    TINY       = 0

    # Prerelease number - nil for release versions
    PRERELEASE = 1

    # The version as a string
    STRING     = %{#{MAJOR}.#{MINOR||0}.#{TINY||0}#{".pre#{PRERELEASE}" if PRERELEASE}}

    # The version as an array
    ARRAY      = [MAJOR || 0, MINOR || 0, TINY || 0, PRERELEASE].compact

    # The version as a string
    def self.to_s
      STRING
    end

    # The version as an array
    def self.to_a
      ARRAY
    end
  end
end
