#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  # Serves as the container where all phases are executed in.
  # Components which define helpers will want to extend this class.
  class Context

    # The Assertion instance this Context was created for
    attr_reader :__test__
    attr_accessor :__phase__

    # Accepts the Assertion instance this Context is created for as first
    # and only argument.
    def initialize(test)
      @__test__  = test
      @__phase__ = :creation
    end
  end
end
