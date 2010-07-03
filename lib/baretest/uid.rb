#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  # Generate a unique ID.
  # Not using uuid simply to avoid two dependencies (uuid, and uuid's dependency
  # 'macaddr'). This should be fine since we don't need a very strong uuid as
  # the use of this library is limited to the scope of a single application
  class UID

    # Base value for the time component in the UID
    Epoch = Time.utc(2000,1,1).to_i # :nodoc:

    # The alphabet for base85 generation
    # It contains all ASCII characters from 33 through 122 except 34, 39, 92,
    # 94 and 96
    # Snippet to generate it: [*33..122].pack("C*").delete('"\'`^\\')
    Base85Alphabet = "!\#$%&()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz"

    # The numeric value of the uid (an Integer)
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

    # @return [String]
    #   A 32 byte long String containing the 16 byte UID in hex representation
    def hex
      "%032x" % @value
    end
    alias base16 hex

    # @return [String]
    #   A 20 byte long String containing the 16 byte UID in base85
    #
    # @see Base85Alphabet
    def base85
      value = @value
      (0..19).map {
        value, character = value.divmod(85)
        Base85Alphabet[character]
      }.join("")
    end
  end
end
