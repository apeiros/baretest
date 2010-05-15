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

    # The current phase being executed
    attr_accessor :__phase__

    # Accepts the Assertion instance this Context is created for as first
    # and only argument.
    def initialize(test)
      @__test__  = test
      @__phase__ = :creation
    end

    # Raises BareTest::Phase::Failure, which causes the Test to get the
    # status :failure.
    def fail(message="Verification failed", *args)
      raise ::BareTest::Phase::Failure.new(@__phase__, message, *args)
    end

    # Raises BareTest::Phase::Pending, which causes the Test to get the
    # status :pending.
    def pending(message="Test is pending", *args)
      raise ::BareTest::Phase::Pending.new(@__phase__, message, *args)
    end

    # Raises BareTest::Phase::Skip, which causes the Test to get the
    # status :skipped.
    def skip(message="Test was skipped", *args)
      raise ::BareTest::Phase::Skip.new(@__phase__, message, *args)
    end
  end
end
