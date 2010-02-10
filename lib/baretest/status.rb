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
    attr_reader :entity

    # The assertions execute context.
    attr_reader :context

    # The status identifier, see BareTest::Status. Symbol.
    attr_reader :status

    # Detailed reason for skipping. Array or nil.
    attr_reader :skip_reason

    # Detailed reason for failing. Array or nil.
    attr_reader :failure_reason

    # If an exception occured in Assertion#execute, this will contain the
    # Exception object raised.
    attr_reader :exception

    # entity::      The suite or Assertion this Status belongs to
    # status::      The status identifier
    # skip_reason::    Why the Assertion or Suite failed.
    #                  Array, String or nil.
    # failure_reason:: Why the Assertion or Suite was skipped.
    #                  Array, String or nil.
    def initialize(entity, status, context=nil, skip_reason=nil, failure_reason=nil, exception=nil)
      @entity         = entity
      @status         = status
      @context        = context
      @skip_reason    = skip_reason
      @failure_reason = failure_reason
      @exception      = exception
    end

    # The failure/error/skipping/pending reason.
    # Returns nil if there's no reason, a string otherwise
    # Options:
    # :default::     Reason to return if no reason is present
    # :separator::   String used to separate multiple reasons
    # :indent::      A String, the indentation to use. Prefixes every line.
    # :first_indent: A String, used to indent the first line only (replaces indent).
    def reason(opt=nil)
      if opt then
        default, separator, indent, first_indent = 
          *opt.values_at(:default, :separator, :indent, :first_indent)
        reason = @skip_reason || @failure_reason || default
        return nil unless reason
        reason = Array(reason)
        reason = reason.join(separator || "\n")
        reason = reason.gsub(/^/, indent) if indent
        reason = reason.gsub(/^#{Regexp.escape(indent)}/, first_indent) if first_indent
        reason
      else
        @reason.empty? ? nil : @reason.join("\n")
      end
    end

    def inspect # :nodoc:
      sprintf "#<%s:0x%08x status=%p exception=%p skip_reason=%p failure_reason=%p entity=%p>",
        self.class,
        object_id>>1,
        @status,
        @exception,
        @skip_reason,
        @failure_reason,
        @entity
    end
  end
end
