$LOAD_PATH.unshift(File.expand_path("#{__FILE__}/../../lib"))
require 'baretest'

BareTest.toplevel_suite.setup do
  @_mymockname = {
    :mocks      => [],
    :failures   => [],
    :exceptions => []
  }
end
BareTest.toplevel_suite.teardown do
  @_mymockname[:mocks].each { |mock|
    mock.teardown(@_mymockname)
  }
  unless @_mymockname[:exceptions].empty? then
    @failure_reason = "An error occurred"
    @exception      = @_mymockname[:exceptions].first
    @status         = :error
  end
  unless @status == :error || @_mymockname[:failures].empty?
    @failure_reason = @_mymockname[:failures].first
    @status         = :failure
  end
end

class DemoMock
  class Error < StandardError; end

  def initialize(action, message)
    @action, @message = action, message
  end

  def teardown(recorder)
    case @action
      when :fail
        recorder[:failures] << @message
      when :raise
        raise @message
    end
  rescue Error => e
    recorder[:exceptions] << e
  end
end

module MockSupport
  def demo_mock(*args, &block)
    mock = DemoMock.new(*args, &block)
    @_mymockname[:mocks] << mock
    mock
  end
end

module BareTest
  class Assertion
    include MockSupport
  end
end