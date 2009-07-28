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
        bt!(caller.size+3)
      end

      def em!
        if @original_assertion.exception then
          puts @original_assertion.exception
        else
          puts "No exception occurred, therefore no error message available"
        end
      end

      def bt!(size=nil)
        if @original_assertion.exception then
          size ||= caller.size+3
          puts @original_assertion.exception.backtrace[0..-size]
        else
          puts "No exception occurred, therefore no backtrace available"
        end
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
      case rv.status
        when :failure
          start_irb_failure_mode(assertion)
          irb_mode_for_assertion(assertion)
          stop_irb_mode(assertion)
        when :error
          start_irb_error_mode(assertion)
          irb_mode_for_assertion(assertion)
          stop_irb_mode(assertion)
      end

      @count[:test]            += 1
      @count[assertion.status] += 1
      rv
    end

    def start_irb_failure_mode(assertion)
      ancestry = assertion.suite.ancestors.reverse.map { |suite| suite.description }

      puts
      puts "#{assertion.status.to_s.capitalize} in:  #{ancestry.join(' > ')}"
      puts "Description: #{assertion.description}"
      if assertion.file then
        code  = irb_code_reindented(assertion.file, assertion.line-1,20)
        match = code.match(/\n^  [^ ]/)
        code[-(match.post_match.size-3)..-1] = ""
        puts "Code:", code
      end
    end

    def start_irb_error_mode(assertion)
      ancestry = assertion.suite.ancestors.reverse.map { |suite| suite.description }

      puts
      puts "#{assertion.status.to_s.capitalize} in:    #{ancestry.join(' > ')}"
      puts "Description: #{assertion.description}"
      puts "Exception:   #{assertion.exception} - #{assertion.exception.backtrace.first}"
      if assertion.file && match = assertion.exception.backtrace.first.match(/^(.*):(\d+)$/) then
        file, line = match.captures
        file = File.expand_path(file)
        if assertion.file == file then
          puts "Code:", irb_code_reindented(file, (assertion.line-1)..(line.to_i))
        end
      end
    end

    def irb_code_reindented(file, from, to=nil)
      lines  = File.readlines(file)
      string = (to ? lines[from, to] : lines[from]).join("")
      string.gsub!(/^\t+/) { |m| "  "*m.size }
      indent = string[/^ +/]
      string.gsub!(/^#{indent}/, '  ')
      string
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
