#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/status'



module BareTest
  class Phase

    attr_accessor :user_file
    attr_accessor :user_line

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

    # nil or CodeBlock
    def user_code
      @user_file && @user_line && CodeBlock.baretest(@user_file, @user_line)
    end
  end
end



require 'baretest/phase/setup'
require 'baretest/phase/exercise'
require 'baretest/phase/verification'
require 'baretest/phase/teardown'
require 'baretest/phase/abortion'
