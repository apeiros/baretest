#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/codeblock'



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

    # The module used to extend the Context object.
    module IRBContext
      def self.extended(obj)
        class <<obj
          remove_method :help rescue nil # this should not be necessary - IRBContext is the highest in the inheritance chain, yet help is taken from IRB::ExtendCommand::Help
        end unless obj.method(:help).inspect =~ /IRBContext/
      end

      attr_accessor :__original_test__
      attr_accessor :__caller_size__

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
             "               starts",
             "nesting!     - a >-separated list of suite descriptions this assertion is nested",
             "description! - this assertion's description",
             "code!        - the code of all phases",
             "eval!        - eval (from_line, number_of_lines) or (from_line..to_line)",
             #"restart! - Restart this irb session, resetting everything",
             "irb_help     - irb's original help",
             "q            - Quit - alias to irb's exit",
             "help         - this text you're reading right now"
      end
      alias help! help

      # lists all available local variables
      alias lv! local_variables

      # Returns the original assertion's status object
      def s!
        @__original_test__.status
      end

      # Returns the original assertion's status code
      def sc!
        @__original_test__.status.code
      end

      # Prints the original assertion's error message and backtrace
      def e!
        em!
        bt!(true)
      end
      
      def c!
        caller
      end

      # Prints the original assertion's error message
      def em!
        status = @__original_test__.status
        if status.exception then
          puts status.exception.message
        elsif status.reason
          puts status.reason
        else
          puts "No exception or failure reason available"
        end
      end

      # Prints the original assertion's backtrace
      def bt!(filter_baretest=true)
        status = @__original_test__.status
        if status.exception then
#           if filter_baretest then
#             backtrace = []
#             status.exception.backtrace.each do |line|
#               break if line =~ %r{(?:/lib/|^)baretest/}
#               backtrace << line
#             end
#           else
#             backtrace = status.exception.backtrace
#           end
          backtrace = status.exception.backtrace
          backtrace = backtrace[0..-@__caller_size__] if filter_baretest
          puts backtrace
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

      def code!
        test   = @__test__
        phases = test.setups+[test.exercise,test.verification]+test.teardowns
        phases.each do |phase|
          puts phase.user_code
          puts
        end
        nil
      end

      # Prints a string of the original assertion's nesting within suites
      def description!
        puts @__test__.description
      end

      # Prints a string of the original assertion's nesting within suites
      def nesting!
        puts @__test__.unit.suite.ancestors[0..-2].reverse.map { |s| s.description }.join(' > ')
      end

      # Quit - an alias to irb's exit
      def q
        exit
      end

      # Exit irb, returning the passed value
      def r(value)
        throw :IRB_RETURN, [true, value]
      end

      # Used for irb's prompt
      def to_s # :nodoc:
        "Context:#{@__phase__}"
      end
    end

    def run_test(test, previous_verification_failed)
      status = super
      case status.code
        when :failure then run_irb_failure(test)
        when :error   then run_irb_error(test)
        # else not needed, nothing to be done for any other status code
      end
      status
    end

    def run_irb_failure(test)
      if reconstructable?(test)
        header "Failure in phase #{test.status.phase}, invoking IRB"
        start_irb_session(test, nil)
      else
        header "Failure in phase #{test.status.phase}, can't invoke IRB", false
      end
    end

    def run_irb_error(test)
      if reconstructable?(test)
        header "Error in phase #{test.status.phase}, invoking IRB"
        highlight_line = test.status.exception.backtrace.first[/:(\d+)/,1].to_i
        start_irb_session(test, highlight_line)
      else
        header "Error in phase #{test.status.phase}, can't invoke IRB", false
      end
    end

    def header(msg, good=true)
      printf "\n\e[1;#{good ? 33 : 31};40m %-79s\e[0m\n", msg
    end

    def code(test, phase, highlight=nil)
      phase_obj = case phase
        when :exercise then test.exercise
        when :verification then test.verification
      end
      if phase_obj then
        puts phase_obj.user_code.options! :highlight => highlight
        puts
      end
    end

    def start_irb_session(test, highlight)
      require 'irb'
      puts
      code(test, test.status.phase, highlight)
      copy                   = reconstruct_context(test)
      puts
      has_returned, returned = irb_drop(copy.context, test)
      # we don't currently do anything with irb's return value
      # later it may serve as to continue running the test, using the supplied
      # return value
    end

    def reconstructable?(test)
      [:exercise, :verification].include?(test.status.phase)
    end

    def reconstruct_context(test)
      status   = test.status
      copy     = test.dup
      executed = []
      copy.run_setup
      executed << "setups"
      if status.phase == :verification then
        copy.run_exercise
        executed << "exercise"
      end
      case executed.size
        when 0 then puts "Executed nothing"
        when 1,2 then puts "Executed #{executed.join(' and ')}"
        else puts "Executed #{executed[0..-2].join(', ')} and #{executed.last}"
      end
      copy.context.__phase__ = status.phase
      copy
    end

    def irb_drop(context, test)
      original_argv = ARGV.dup
      ARGV.replace([]) # IRB is being stupid
      unless defined? ::IRB_SETUP
        ::IRB.setup(nil)
        Object.const_set(:IRB_SETUP, true)
      end
      irb = ::IRB::Irb.new(IRB::WorkSpace.new(context))
      ::IRB.conf[:IRB_RC].call(irb.context) if ::IRB.conf[:IRB_RC] # loads the irbrc?
      ::IRB.conf[:MAIN_CONTEXT] = irb.context # why would the main context be set here?
      trap("SIGINT") do irb.signal_handle end
      ARGV.replace(original_argv)
      context.extend IRBContext
      context.__original_test__ = test
      context.__caller_size__ = caller.size+7 # subject to change along with the implementation
      catch(:IRB_RETURN) {
        catch(:IRB_EXIT) { irb.eval_input }
        [false, nil]
      }
    end
  end
end
