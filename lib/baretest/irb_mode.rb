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
        throw :IRB_EXIT, value
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
        require 'irb'
        copy = reconstruct_context(test)
        p :returned => irb_drop(copy.context)
      else
        puts "irb_failure, #{test.status.phase} - irreconstructable"
      end
    end

    def run_irb_error(test)
      if reconstructable?(test)
        require 'irb'
        copy = reconstruct_context(test)
        p :returned => irb_drop(copy.context)
      else
        puts "irb_error, #{test.status.phase} - irreconstructable"
      end
    end

    def reconstructable?(test)
      [:exercise, :verification].include?(test.status.phase)
    end

    def reconstruct_context(test)
      status = test.status
      copy   = test.dup
      copy.run_setup
      puts "executed setups"
      if status.phase == :verification then
        copy.run_exercise
        puts "executed exercise"
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
      ws  = ::IRB::WorkSpace.new(context)
      irb = ::IRB::Irb.new(ws)
      ::IRB.conf[:IRB_RC].call(irb.context) if ::IRB.conf[:IRB_RC] # loads the irbrc?
      ::IRB.conf[:MAIN_CONTEXT] = irb.context # why would the main context be set here?
      trap("SIGINT") do irb.signal_handle end
      ARGV.replace(original_argv)
      context.extend IRBContext
      context.instance_variable_set(:@irb, irb)
      context.instance_variable_set(:@ws, ws)
      catch(:IRB_EXIT) do irb.eval_input end
    end
  end
end
