# encoding: utf-8

#--
# Copyright 2007-2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++




module Kernel
  # Short for SilverPlatter::Project::Version.string.
  # See SilverPlatter::Project::Version::string for proper format.
  def Version(string)
    SilverPlatter::Project::Version.string(string)
  end

  # be a good ruby citizen and make the pseudo-function private and available
  # as Kernel::Version
  module_function :Version
end

module SilverPlatter
  class Project
    # Provides methods for dealing with version strings
    class Version
      include Comparable

      # the regular expression used for parsing non conformant strings
      SCAN     = /\d+|[^\.\d ]+/

      # recognize an item as beeing integer only
      INTEGER  = /\A\d+\z/

      # the regular expression to match the number part of conforming
      # version strings
      NUMBERS  = /\A(\d+)(?:\.(\d+)(?:\.(\d+))?)?(?:([abgf])(\d+)?)?/

      # the regular expression to match the date part of conforming
      # version strings
      DATETIME = / (\d{4})-(\d{2})-(\d{2})(?:T(\d{2})(?::(\d{2}))?(?::(\d{2}))?Z?)?\z|\z/

      # the weighting of alphanumeric expressions in numbers
      REPLACE = [
        [/\Aalpha\z/i,      -10],
        [/\Abeta\z/i,        -9],
        [/\Aexp\w*\z/i,      -9],
        [/\Adev\w*\z/i,      -8],
        [/\Agamma\z/i,       -8],
        [/\Aunstable\z/i,    -8],
        [/\Adelta\z/i,       -7],
        [/\Astable\z/i,      -7],
        [/\Aproduction\z/i,  -6],
        [/\Aa\z/iu,         -10],
        [/\Aα\z/iu,         -10],
        [/\Ab\z/iu,          -9],
        [/\Aß\z/iu,          -9],
        [/\Aβ\z/iu,          -9],
        [/\Ag\z/iu,          -8],
        [/\Aγ\z/iu,          -8],
        [/\Ad\z/iu,          -7],
        [/\A∂\z/iu,          -7],
        [/\Aδ\z/iu,          -7],
      ]

      # for textual representation of the version
      TO_S = Hash.new{|h,k|k.to_s}.merge({
        -10 => "a",
        -9 => "b",
        -8 => "g",
        -7 => "d",
        -6 => "f",
      })

      def self.binary(string)
        raise "broken"
        num = string.unpack("I").first
        ver = []
        4.times {
          num, cur = *num.divmod(256)
          ver << cur-20
        }
        ver.shift while ver[0] == 0
        new(*ver.reverse)
      end

      def self.parse(string)
        new(*string.scan(SCAN).map { |item|
          if item =~ INTEGER then
            Integer(item)
          elsif replace = REPLACE.find { |(expr, replacement)| item =~ expr } then
            replace[1]
          else
            raise ArgumentError, "Unrecognized Token #{item.inspect} in #{string}"
          end
        })
      end

      # Expects a specific string format, examples of valid version strings are:
      # "1"
      # "1.5.3"
      # "1.5.3a01"
      # "1.5.3a01 2007-03-15"
      # "1.5 2007-03-15T23:05:23Z"
      def self.string(string)
        string  = string.to_str
        numbers = string.match(NUMBERS)
        date    = string.match(DATETIME)
        raise ArgumentError, "Invalid Versionstring #{string.inspect}, use #{self}.parse()" unless numbers and numbers[0]+date[0] == string
        version = numbers.captures
        if date[1] then
          version << Time.mktime(date[1], date[2]||0, date[3]||0, date[4]||0, date[5]||0, date[6]||0)
        else
          version << nil
        end
        new(*version)
      end

      attr_reader :major
      attr_reader :minor
      attr_reader :patch
      attr_reader :level
      attr_reader :date
      attr_reader :segments

      def initialize(major, minor=nil, patch=nil, status=nil, level=nil, date=nil)
        @major    = major.to_i
        @minor    = (minor || 0).to_i
        @patch    = (patch || 0).to_i
        @status   = {"a"=>-10,"b"=>-9,"g"=>-8,"f"=>-6,nil=>-6}[status]
        @level    = (level || 1).to_i
        @date     = date
        if @date then
          @segments = [@major, @minor, @patch, @status, @level, @date].freeze
        else
          @segments = [@major, @minor, @patch, @status, @level].freeze
        end
      end

      def status
        TO_S[@status]
      end

      def binary
        raise "broken"
        segments = @segments[0,4]
        segments << 0 if segments.length < 4
        [segments.inject(0) { |s,e| (s<<8)+(e+20) }].pack("I")
      end

      def <=>(other)
        raise TypeError, "#{other} is not a version" unless other.kind_of?(SilverPlatter::Project::Version)
        @segments <=> other.segments
      end

      def [](*index)
        @segments[*index]
      end

      def to_str
        "%d.%d.%d%s%02d#{@date.strftime(' %Y-%m-%dT%H:%M:%SZ') if @date}"%[@major, @minor, @patch, TO_S[@status], @level]
      end
      alias to_s to_str

      #def to_s
      #	@segments[1..-1].inject(@segments[0].to_s) { |str,seg|
      #		str+(seg < 0 ? " #{TO_S[seg]}" : ".#{TO_S[seg]}")
      #	}
      #end

      def to_a
        @segments.dup
      end

      def to_hash
        {
          :major  => @major,
          :minor  => @minor,
          :patch  => @patch,
          :status => @status,
          :level  => @level,
          :date   => @date
        }
      end

      def hash # :nodoc:
        @segments.hash
      end

      def eql?(other) # :nodoc:
        self.class == other.class && @segments == other.segments
      end

      def inspect # :nodoc:
        "<Version: #{self}>"
      end

      Version = Version("1.0.0 2007-03-15")
    end
  end
end