#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  # Generate a unique ID.
  # Not using uuid simply to avoid two dependencies (uuid, and uuid's dependency
  # 'macaddr').
  class UID

    # :nodoc:
    Epoch = Time.utc(2000,1,1).to_i

    attr_reader :value

    # Returns a 32byte long String containing a new 16 byte random value
    # in hex representation
    def self.hex_uid
      new.hex
    end

    # Create a 128bit (16 Byte) long random number
    def initialize
      now = Time.now
      
      # Works for the next 100 years - should be enough
      # after that, it'll wrap around.
      time_part_52   = (((now.to_i-Epoch) & 0xffffffff) << 20) + now.usec

      # Not solid, but for the purposes, should work
      process_part32 = (Thread.current.object_id ^ Process.pid) & 0xfffffffff

      # Add a bit of random noise
      random_part44  = Kernel.rand(0x100000000000)

      @value = (random_part44 << 84) + (process_part32 << 52) + time_part_52
    end

    # Returns a 32byte long String containing the 16 byte random value
    # in hex representation
    def hex
      "%032x" % @value
    end
  end
end
