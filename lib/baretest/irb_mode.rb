#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



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
             "eval!        - eval (from_line, number_of_lines) or (from_line..to_line)",
             #"restart! - Restart this irb session, resetting everything",
             "irb_help     - irb's original help",
             "q            - Quit - alias to irb's exit",
             "help         - this text you're reading right now"
      end
      alias help! help

      # Used for irb's prompt
      def to_s # :nodoc:
        "Context:#{@__phase__}"
      end

      # Quit - an alias to irb's exit
      def q
        exit
      end

      # Exit irb, returning the passed value
      def r(value)
        throw :IRB_RETURN, [true, value]
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
        code(test, test.status.phase)
        start_irb_session(test)
      else
        header "Failure in phase #{test.status.phase}, can't invoke IRB", false
      end
    end

    def run_irb_error(test)
      if reconstructable?(test)
        header "Error in phase #{test.status.phase}, invoking IRB"
        code(test, test.status.phase)
        start_irb_session(test)
      else
        header "Error in phase #{test.status.phase}, can't invoke IRB", false
      end
    end

    def header(msg, good=true)
      printf "\n\e[1;#{good ? 32 : 31};40m %-79s\e[0m\n", msg
    end

    def code(test, phase)
      phase_obj = case phase
        when :exercise then test.exercise
        when :verification then test.verification
      end
      if phase_obj then
        puts "Code of #{phase_obj.user_file}:#{phase_obj.user_line}"
        puts insert_line_numbers(phase_obj.user_code, phase_obj.user_line)
        puts
      end
    end

    def insert_line_numbers(code, start_line=1)
      digits       = Math.log10(start_line+code.count("\n")).floor+1
      current_line = start_line-1
      code.gsub(/^/) { sprintf '  %0*d  ', digits, current_line+=1 }
    end

    def start_irb_session(test)
      require 'irb'
      copy                   = reconstruct_context(test)
      has_returned, returned = irb_drop(copy.context)
      # we don't currently do anything with irb's return value
      # later it may serve as to continue running the test, using the supplied
      # return value
    end

    def reconstructable?(test)
      [:exercise, :verification].include?(test.status.phase)
    end

    def reconstruct_context(test)
      status = test.status
      copy   = test.dup
      copy.run_setup
      puts "-> executed setups"
      if status.phase == :verification then
        copy.run_exercise
        puts "-> executed exercise"
      end
      copy.context.__phase__ = status.phase
      copy
    end

    def irb_drop(context=nil, *argv)
      original_argv = ARGV.dup
      ARGV.replace(argv) # IRB is being stupid
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
      catch(:IRB_RETURN) {
        catch(:IRB_EXIT) { irb.eval_input }
        [false, nil]
      }
    end
  end
end
