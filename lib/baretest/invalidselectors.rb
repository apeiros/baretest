#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  # Raised by BareTest.process_selectors if one or more invalid selectors are
  # passed in.
  class InvalidSelectors < StandardError
    attr_reader :selectors

    def initialize(selectors)
      @selectors = selectors
      super("Invalid selectors: #{selectors.join(', ')}")
    end
  end
end
