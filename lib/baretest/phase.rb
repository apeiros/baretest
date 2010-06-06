#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/status'



module BareTest
  class Phase
    def self.extract_code(data)
      if data.is_a?(String) then
        data
      elsif data.is_a?(Proc) && defined?(ParseTree) && defined?(Ruby2Ruby) then
        data.to_ruby
      else
        "<<could not extract code>>"
      end
    end

    def initialize(&code)
      @code      ||= code
      @user_file ||= nil
      @user_line ||= nil
      @user_code ||= nil
    end

    def phase
      raise "Your Phase subclass #{self.class.to_s} must override #phase."
    end

    def execute(test)
      raise Pending.new(phase, "No code provided") unless @code # no code? that means pending

      context = test.context
      context.__phase__ = phase
      context.instance_eval(&@code)
    end

    def user_code
      @user_code ? Phase.extract_code(@user_code) : "<<could not extract code>>"
    end

    def user_file
      @user_file || "?"
    end

    def user_line
      @user_line || "?"
    end
  end
end



require 'baretest/phase/setup'
require 'baretest/phase/exercise'
require 'baretest/phase/verification'
require 'baretest/phase/teardown'
require 'baretest/phase/abortion'
