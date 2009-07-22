#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  module IRBMode
    module AssertionExtensions
    end

    class AssertionContext < ::BareTest::Assertion
      attr_accessor :original_assertion

      def to_s
        "Assertion"
      end

      def e!
        em!
        bt!
      end

      def em!
        puts @original_assertion.exception
      end

      def bt!
        size = caller.size+3
        puts @original_assertion.exception.backtrace[0..-size]
      end
    end

    def self.extended(by)
      by.init do
        require 'irb'
        require 'pp'
        require 'yaml'
        IRB.setup(nil) # must only be called once
      end
    end

    # Formatter callback.
    # Invoked once for every assertion.
    # Gets the assertion to run as single argument.
    def run_test(assertion)
      rv = super
      # drop into irb if assertion failed
      if [:failure, :error].include?(rv.status) then
        start_irb_mode(assertion)
        irb_mode_for_assertion(assertion)
        stop_irb_mode(assertion)
      end

      @count[:test]            += 1
      @count[assertion.status] += 1
      rv
    end

    def start_irb_mode(assertion)
      ancestry = assertion.suite.ancestors.reverse.map { |suite| suite.name }

      puts
      puts "#{assertion.status.to_s.capitalize} in #{ancestry.join(' > ')}"
      puts "  #{assertion.description}"
      puts "#{assertion.exception} - #{assertion.exception.backtrace.first}"
      super
    rescue NoMethodError # HAX, not happy about that. necessary due to order of extend
    end

    # This method is highlevel hax, try to add necessary API to
    # Test::Assertion
    def irb_mode_for_assertion(assertion)
      irb_context = assertion.clean_copy(AssertionContext)
      irb_context.original_assertion = assertion
      irb_context.setup
      @irb = IRB::Irb.new(IRB::WorkSpace.new(irb_context.send(:binding)))
      irb  = @irb # for closure
      # HAX - cargo cult, taken from irb.rb, not yet really understood.
      IRB.conf[:IRB_RC].call(irb.context) if IRB.conf[:IRB_RC] # loads the irbrc?
      IRB.conf[:MAIN_CONTEXT] = irb.context # why would the main context be set here?
      # /HAX

      trap("SIGINT") do
        irb.signal_handle
      end
      catch(:IRB_EXIT) do irb.eval_input end

      irb_context.teardown
    end

    def stop_irb_mode(assertion)
      puts
      super
    rescue NoMethodError # HAX, not happy about that. necessary due to order of extend
    end
  end
end
