#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  # The status of an Assertion or Suite, including failure- and skipreasons,
  # or in case of exceptions, the exception itself and in what phase it occurred
    # An assertion or suite has 9 possible states:
    # :success:: The assertion passed. This means the block returned a trueish value.
    # :failure:: The assertion failed. This means the block returned a falsish value.
    #            Alternatively it raised an Assertion::Failure.
    #            The latter has the advantage that it can provide nicer diagnostics.
    # :pending:: No block given to the assertion to be run
    # :skipped:: If one of the parent suites is missing a dependency, its assertions
    #            will be skipped
    #            Alternatively it raised an Assertion::Skip.
    # :error::   The assertion errored out. This means the block raised an exception
  class Status

    # The assertion or suite this status belongs to. Assertion or Suite.
    attr_reader :test
    alias entity test

    # The assertions execute context.
    attr_reader :phase

    # The status identifier. Symbol.
    attr_reader :code

    # Detailed reason for the status. Success usually has no reason. String or nil.
    attr_reader :reason

    # If an exception occured in Assertion#execute, this will contain the
    # Exception object raised.
    attr_reader :exception

    # entity::      The suite or Assertion this Status belongs to
    # status::      The status identifier
    # skip_reason::    Why the Assertion or Suite failed.
    #                  Array, String or nil.
    # failure_reason:: Why the Assertion or Suite was skipped.
    #                  Array, String or nil.
    def initialize(test, code, phase, reason=nil, exception=nil)
      @test      = test
      @code      = code
      @phase     = phase
      @reason    = reason
      @exception = exception
    end

    def inspect # :nodoc:
      sprintf "#<%s:0x%08x status=%p exception=%p skip_reason=%p failure_reason=%p entity=%p>",
        self.class,
        object_id>>1,
        @code,
        @exception,
        @skip_reason,
        @failure_reason,
        @entity
    end
  end
end
