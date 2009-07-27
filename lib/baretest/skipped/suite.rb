#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/skipped/assertion'



module BareTest
  # Skipped contains variants of Suite and Assertion.
  # See Skipped::Suite and Skipped::Assertion
  module Skipped
    # Like Test::Suite, but all Assertions are defined as Skipped::Assertion
    class Suite < ::BareTest::Suite
      def self.create(description=nil, parent=nil, opts={}, &block)
        new(description, parent, &block) # Skipped::Suite always
      end

      # :nodoc:
      # All Assertions use Skipped::Assertion instead of Test::Assertion.
      def assert(description=nil, &block)
        @skipped << Skipped::Assertion.new(self, description, &block)
      end

      # :nodoc:
      # All setup blocks are disabled
      def ancestry_setup
        []
      end

      # :nodoc:
      # All teardown blocks are disabled
      def ancestry_teardown
        []
      end

      # :nodoc:
      # All setup blocks are disabled
      def setup(&block)
        []
      end

      # :nodoc:
      # All teardown blocks are disabled
      def teardown(&block)
        []
      end
    end

  end
end
