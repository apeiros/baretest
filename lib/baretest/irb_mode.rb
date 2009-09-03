#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'stringio' # for silencing HAX



module Kernel
  alias lv! local_variables
  private :lv!
end

module BareTest
  module IRBMode
    module AssertionExtensions
    end

    class AssertionContext < ::BareTest::Assertion
      attr_accessor :original_assertion

      def help
        puts "Available methods:",
             "s!          - the original assertions' status",
             "e!          - prints the error message and full backtrace",
             "em!         - prints the error message",
             "bt!         - prints the full backtrace",
             "lv!         - lists all available local variables",
             "iv!         - lists all available instance variables",
             "cv!         - lists all available class variables",
             "gv!         - lists all available global variables",
             "file        - the file this assertion was defined in",
             "line        - the line number in the file where this assertion's definition starts",
             "nesting     - a >-separated list of suite descriptions this assertion is nested in",
             "description - this assertion's description",
             "code        - the code of this assertion",
             #"restart! - Restart this irb session, resetting everything",
             "irb_help    - irb's original help"
             "help        - this text you're reading right now"
      end

      def to_s
        "Assertion"
      end

      def s!
        @original_assertion.status
      end

      def e!
        em!
        bt!(caller.size+3)
      end

      def em!
        if @original_assertion.exception then
          puts @original_assertion.exception
        else
          puts "No exception occurred, therefore no error message is available"
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

      def iv!
        instance_variables.sort
      end

      def cv!
        self.class.class_variables.sort
      end

      def gv!
        global_variables.sort
      end

      def nesting
        suite.ancestors[0..-2].reverse.map { |suite| suite.description }.join(' > ')
      end

      def code
        puts(@code || "Code could not be extracted")
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

      rv
    end

    def start_irb_failure_mode(assertion)
      ancestry = assertion.suite.ancestors.reverse.map { |suite| suite.description }

      puts
      puts "#{assertion.status.to_s.capitalize} in:  #{ancestry[1..-1].join(' > ')}"
      puts "Description: #{assertion.description}"
      if assertion.file then
        code  = irb_code_reindented(assertion.file, assertion.line-1,20)
        match = code.match(/\n^  [^ ]/)
        code[-(match.post_match.size-3)..-1] = ""
        assertion.instance_variable_set(:@code, code)
        puts "Code:", code
      end
    end

    def start_irb_error_mode(assertion)
      ancestry = assertion.suite.ancestors.reverse.map { |suite| suite.description }

      puts
      puts "#{assertion.status.to_s.capitalize} in:    #{ancestry[1..-1].join(' > ')}"
      puts "Description: #{assertion.description}"
      puts "Exception:   #{assertion.exception} in file #{assertion.exception.backtrace.first}"
      if assertion.file && match = assertion.exception.backtrace.first.match(/^(.*):(\d+)$/) then
        file, line = match.captures
        file = File.expand_path(file)
        if assertion.file == file then
          code = irb_code_reindented(file, (assertion.line-1)..(line.to_i))
          assertion.instance_variable_set(:@code, code)
          puts "Code:", code
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
      if assertion.instance_variable_defined?(:@code) then
        code = assertion.instance_variable_get(:@code)
        irb_context.instance_variable_set(:@code, code)
        Readline::HISTORY.push(*code.split("\n")[1..-2])
      end
      irb_context.original_assertion = assertion
      irb_context.setup

      $stdout = StringIO.new # HAX - silencing 'irb: warn: can't alias help from irb_help.' - find a better way
      irb = IRB::Irb.new(IRB::WorkSpace.new(irb_context.send(:binding)))
      $stdout = STDOUT # /HAX
      # HAX - cargo cult, taken from irb.rb, not yet really understood.
      IRB.conf[:IRB_RC].call(irb.context) if IRB.conf[:IRB_RC] # loads the irbrc?
      IRB.conf[:MAIN_CONTEXT] = irb.context # why would the main context be set here?
      # /HAX

      trap("SIGINT") do irb.signal_handle end
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
