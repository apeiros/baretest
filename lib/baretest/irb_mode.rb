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
    RemoveGlobals = %w[
      $! $" $$ $& $' $* $+ $, $-0 $-F $-I $-K $-a $-d $-i $-l $-p $-v $-w $. $/
      $0 $: $; $< $= $> $? $@ $FS $NR $OFS $ORS $PID $RS $\\ $_ $` $~
      $ARGV $CHILD_STATUS $DEBUG $DEFAULT_INPUT $DEFAULT_OUTPUT $ERROR_INFO
      $ERROR_POSITION $FIELD_SEPARATOR $FILENAME $IGNORECASE $INPUT_LINE_NUMBER
      $INPUT_RECORD_SEPARATOR $KCODE $LAST_MATCH_INFO $LAST_PAREN_MATCH
      $LAST_READ_LINE $LOADED_FEATURES $LOAD_PATH $MATCH $OUTPUT_FIELD_SEPARATOR
      $OUTPUT_RECORD_SEPARATOR $POSTMATCH $PREMATCH $PROCESS_ID $PROGRAM_NAME
      $SAFE $VERBOSE $stderr $stdin $stdout
    ]

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

      attr_accessor :__status__

      # Prints a list of available helper methods
      def help
        puts "Available methods:",
             "s!           - the assertions' original status",
             "sc!          - the assertions' original status code",
             "e!           - prints the error message and full backtrace",
             "em!          - prints the error message",
             "bt!          - prints the full backtrace",
             "lv!          - lists all available local variables",
             "iv!          - lists all available instance variables",
             "cv!          - lists all available class variables",
             "gv!          - lists all available global variables, per default dropping rubys",
             "               standard globals (use gv!(false) to avoid that)",
             "file!        - the file this assertion was defined in",
             "line!        - the line number in the file where this assertion's definition",
             "               starts",
             "nesting!     - a >-separated list of suite descriptions this assertion is nested",
             "description! - this assertion's description",
             "code!        - the code of this assertion",
             #"restart! - Restart this irb session, resetting everything",
             "irb_help     - irb's original help",
             "help         - this text you're reading right now"
      end
      alias help! help

      def to_s # :nodoc:
        "Context"
      end

      def q
        exit
      end

      # Returns the original assertion's status
      def s!
        @__status__
      end

      # Returns the original assertion's status code
      def sc!
        @__status__.status
      end

      # Prints the original assertion's error message and backtrace
      def e!
        em!
        bt!(caller.size+3)
      end

      # Prints the original assertion's error message
      def em!
        if @__status__.exception then
          puts @__status__.exception.message
        elsif @__status__.failure_reason
          puts @__status__.failure_reason
        else
          puts "No exception or failure reason available"
        end
      end

      # Prints the original assertion's backtrace
      def bt!(size=nil)
        if @__status__.exception then
          size ||= caller.size+3
          puts @__status__.exception.backtrace[0..-size]
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
      def gv!(remove_standard=true)
        puts *(global_variables-(remove_standard ? IRBMode::RemoveGlobals : [])).sort
      end

      # Returns the original assertion's file
      def file!
        puts @__assertion__.file
      end

      # Returns the original assertion's line
      def line!
        puts @__assertion__.line
      end

      # Returns the original assertion's line
      def open!
        `bbedit '#{@__assertion__.file}:#{@__assertion__.line}'`
      end

      # Prints a string of the original assertion's nesting within suites
      def description!
        puts @__assertion__.description
      end

      # Prints a string of the original assertion's nesting within suites
      def nesting!
        puts @__assertion__.suite.ancestors[0..-2].reverse.map { |s| s.description }.join(' > ')
      end

      # Prints the code of the assertion
      # Be aware that this relies on your code being properly indented.
      def code!
        if code = @__assertion__.code then
          puts(insert_line_numbers(code, @__assertion__.line-1))
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
    def run_test(assertion, with_setup)
      rv = super
      # drop into irb if assertion failed
      case rv.status
        when :failure
          start_irb_failure_mode(assertion, rv)
          irb_mode_for_assertion(assertion, rv, with_setup)
          stop_irb_mode
        when :error
          start_irb_error_mode(assertion, rv)
          irb_mode_for_assertion(assertion, rv, with_setup)
          stop_irb_mode
        # with other states, irb-mode is not started
      end

      rv
    end

    # Invoked when we have to drop into irb mode due to a failure
    def start_irb_failure_mode(assertion, status) # :nodoc:
      ancestry = assertion.suite.ancestors.reverse.map { |suite| suite.description }

      puts
      puts "#{status.status.to_s.capitalize} in:  #{ancestry[1..-1].join(' > ')}"
      puts "Description: #{assertion.description}"
      if file = assertion.file then
        code  = irb_code_reindented(file, assertion.line-1,25)
        match = code.match(/\n^  [^ ]/)
        code[-(match.post_match.size-3)..-1] = "" if match
        code << "\n... (only showing first 25 lines)" unless match
        assertion.code = code
        puts "Code (#{file}):", insert_line_numbers(code, assertion.line-1)
      end
    end

    # Invoked when we have to drop into irb mode due to an error
    def start_irb_error_mode(assertion, status) # :nodoc:
      ancestry = assertion.suite.ancestors.reverse.map { |suite| suite.description }

      puts
      puts "#{status.status.to_s.capitalize} in:    #{ancestry[1..-1].join(' > ')}"
      puts "Description: #{assertion.description}"
      puts "Exception:   #{status.exception} in file #{status.exception.backtrace.first}"
      if assertion.file && match = status.exception.backtrace.first.match(/^([^:]+):(\d+)(?:$|:in .*)/) then
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
    def irb_mode_for_assertion(assertion, status, with_setup) # :nodoc:
      irb_context = ::BareTest::Assertion::Context.new(assertion)
      irb_context.extend IRBContext
      irb_context.__status__ = status
      assertion.execute_phase(:setup, irb_context, with_setup.map { |s| s.block })

      $stdout = StringIO.new # HAX - silencing 'irb: warn: can't alias help from irb_help.' - find a better way
      irb = IRB::Irb.new(IRB::WorkSpace.new(irb_context))
      $stdout = STDOUT # /HAX
      # HAX - cargo cult, taken from irb.rb, not yet really understood.
      IRB.conf[:IRB_RC].call(irb.context) if IRB.conf[:IRB_RC] # loads the irbrc?
      IRB.conf[:MAIN_CONTEXT] = irb.context # why would the main context be set here?
      # /HAX

      trap("SIGINT") do irb.signal_handle end

      if code = assertion.code then
        #irb_context.code = code
        Readline::HISTORY.push(*code.split("\n")[1..-2])
      end

      catch(:IRB_EXIT) do irb.eval_input end

      assertion.execute_phase(:teardown, irb_context, assertion.suite.ancestry_teardown)
    end

    # Invoked when we leave the irb session
    def stop_irb_mode # :nodoc:
      puts
    end
  end
end
