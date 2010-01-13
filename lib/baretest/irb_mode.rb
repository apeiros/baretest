#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'stringio' # for silencing HAX



module Kernel
  alias lv! local_variables
  private :lv!
end

module BareTest

  # For internal use only.
  #
  # This module extends BareTest::Run if --interactive/-i is used
  #
  # See BareTest::IRBMode::AssertionContext for some methods IRBMode adds to Assertion for
  # use within the irb session.
  module IRBMode # :nodoc:
    @irb_setup = false

    def self.irb_setup! # :nodoc:
      @irb_setup = true
    end

    def self.irb_setup? # :nodoc:
      @irb_setup
    end

    # The class used to recreate the failed/errored assertion's context.
    # Adds several methods over plain Assertion.
    module IRBContext

      attr_accessor :__original__

      # Prints a list of available helper methods
      def help
        puts "Available methods:",
             "s!          - the original assertions' status",
             "e!          - prints the error message and full backtrace",
             "em!         - prints the error message",
             "bt!         - prints the full backtrace",
             "iv!         - lists all available instance variables",
             "cv!         - lists all available class variables",
             "gv!         - lists all available global variables",
             "file        - the file this assertion was defined in",
             "line        - the line number in the file where this assertion's definition starts",
             "nesting     - a >-separated list of suite descriptions this assertion is nested in",
             "description - this assertion's description",
             "code        - the code of this assertion",
             #"restart! - Restart this irb session, resetting everything",
             "irb_help    - irb's original help",
             "help        - this text you're reading right now"
      end

      def to_s # :nodoc:
        "Context"
      end

      # Returns the original assertion's status
      def s!
        p @__original__.status
      end

      # Prints the original assertion's error message and backtrace
      def e!
        em!
        bt!(caller.size+3)
      end

      # Prints the original assertion's error message
      def em!
        if @__original__.exception then
          puts @__original__.exception.message
        elsif @__original__.reason
          puts @__original__.reason
        else
          puts "No exception occurred, therefore no error message is available"
        end
      end

      # Prints the original assertion's backtrace
      def bt!(size=nil)
        if @__original__.exception then
          size ||= caller.size+3
          puts @__original__.exception.backtrace[0..-size]
        else
          puts "No exception occurred, therefore no backtrace is available"
        end
      end

      # Returns an array of all instance variable names
      def iv!
        puts *instance_variables.sort
      end

      # Returns an array of all class variable names
      def cv!
        puts *self.class.class_variables.sort
      end

      # Returns an array of all global variable names
      def gv!
        puts *global_variables.sort
      end

      # Prints a string of the original assertion's nesting within suites
      def description
        puts @__original__.description
      end

      # Prints a string of the original assertion's nesting within suites
      def nesting
        puts @__original__.suite.ancestors[0..-2].reverse.map { |s| s.description }.join(' > ')
      end

      # Prints the code of the assertion
      # Be aware that this relies on your code being properly indented.
      def code!
        if code = @__original__.code then
          puts(insert_line_numbers(code, @__original__.line-1))
        else
          puts "Code could not be extracted"
        end
      end

      def insert_line_numbers(code, start_line=1)
        digits       = Math.log10(start_line+code.count("\n")).floor+1
        current_line = start_line-1
        code.gsub(/^/) { sprintf '  %0*d  ', digits, current_line+=1 }
      end
    end

    # Install the init handler
    def self.extended(by) # :nodoc:
      by.init do
        require 'irb'
        require 'pp'
        require 'yaml'
        IRB.setup(nil) unless ::BareTest::IRBMode.irb_setup? # must only be called once
        ::BareTest::IRBMode.irb_setup!
      end
    end

    # Formatter callback.
    # Invoked once for every assertion.
    # Gets the assertion to run as single argument.
    def run_test(assertion, setup)
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

    # Invoked when we have to drop into irb mode due to a failure
    def start_irb_failure_mode(assertion) # :nodoc:
      ancestry = assertion.suite.ancestors.reverse.map { |suite| suite.description }

      puts
      puts "#{assertion.status.to_s.capitalize} in:  #{ancestry[1..-1].join(' > ')}"
      puts "Description: #{assertion.description}"
      if file = assertion.file then
        code  = irb_code_reindented(file, assertion.line-1,20)
        match = code.match(/\n^  [^ ]/)
        code[-(match.post_match.size-3)..-1] = ""
        assertion.code = code
        puts "Code (#{file}):", insert_line_numbers(code, assertion.line-1)
      end
    end

    # Invoked when we have to drop into irb mode due to an error
    def start_irb_error_mode(assertion) # :nodoc:
      ancestry = assertion.suite.ancestors.reverse.map { |suite| suite.description }

      puts
      puts "#{assertion.status.to_s.capitalize} in:    #{ancestry[1..-1].join(' > ')}"
      puts "Description: #{assertion.description}"
      puts "Exception:   #{assertion.exception} in file #{assertion.exception.backtrace.first}"
      if assertion.file && match = assertion.exception.backtrace.first.match(/^([^:]+):(\d+)(?:$|:in .*)/) then
        file, line = match.captures
        file = File.expand_path(file)
        if assertion.file == file then
          code = irb_code_reindented(file, (assertion.line-1)..(line.to_i))
          assertion.code = code
          puts "Code (#{file}):", insert_line_numbers(code, assertion.line-1)
        end
      end
    end

    # Nicely reformats the assertion's code
    def irb_code_reindented(file, *slice) # :nodoc:
      lines  = File.readlines(file)
      string = lines[*slice].join("").sub(/[\r\n]*\z/, '')
      string.gsub!(/^\t+/) { |m| "  "*m.size }
      indent = string[/^ +/]
      string.gsub!(/^#{indent}/, '  ')

      string
    end

    def insert_line_numbers(code, start_line=1)
      digits       = Math.log10(start_line+code.count("\n")).floor+1
      current_line = start_line-1
      code.gsub(/^/) { sprintf '  %0*d  ', digits, current_line+=1 }
    end

    # This method is highlevel hax, try to add necessary API to Test::Assertion
    # Drop into an irb shell in the context of the assertion passed as an argument.
    # Uses Assertion#clean_copy(AssertionContext) to create the context.
    # Adds the code into irb's history.
    def irb_mode_for_assertion(original_assertion) # :nodoc:
      assertion = original_assertion.clone
      assertion.reset
      irb_context = assertion.context
      irb_context.extend IRBContext
      irb_context.__original__ = original_assertion
      assertion.setup

      $stdout = StringIO.new # HAX - silencing 'irb: warn: can't alias help from irb_help.' - find a better way
      irb = IRB::Irb.new(IRB::WorkSpace.new(irb_context))
      $stdout = STDOUT # /HAX
      # HAX - cargo cult, taken from irb.rb, not yet really understood.
      IRB.conf[:IRB_RC].call(irb.context) if IRB.conf[:IRB_RC] # loads the irbrc?
      IRB.conf[:MAIN_CONTEXT] = irb.context # why would the main context be set here?
      # /HAX

      trap("SIGINT") do irb.signal_handle end

      if code = original_assertion.code then
        #irb_context.code = code
        Readline::HISTORY.push(*code.split("\n")[1..-2])
      end

      catch(:IRB_EXIT) do irb.eval_input end

      assertion.teardown
    end

    # Invoked when we leave the irb session
    def stop_irb_mode(assertion) # :nodoc:
      puts
      super
    rescue NoMethodError # HAX, not happy about that. necessary due to order of extend
    end
  end
end
