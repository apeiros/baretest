#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Run

    # CLI runner is invoked with `-f cli` or `--format cli`.
    # It is intended for use with an interactive shell, to provide a comfortable, human
    # readable output.
    # It prints colored output (requires ANSI colors compatible terminal).
    #
    module CLI # :nodoc:
      extend Formatter

      option_defaults :color   => true,
                      :profile => false

      text "Options for 'CLI' formatter:\n"

      option          :color,   '-c', '--[no-]color',   :Boolean, 'Enable/disable output coloring'
      option          :profile, '-p', '--[no-]profile', :Boolean, 'Enable/disable profiling assertions'

      text "\nEnvironment variables for 'CLI' formatter:\n"

      env_option      :color,   'COLOR'
      env_option      :profile, 'PROFILE'

      Formats = {
        :pending            => "\e[43m%9s\e[0m  %s%s\n",
        :manually_skipped   => "\e[43m%9s\e[0m  %s%s\n",
        :dependency_missing => "\e[43m%9s\e[0m  %s%s\n",
        :library_missing    => "\e[43m%9s\e[0m  %s%s\n",
        :component_missing  => "\e[43m%9s\e[0m  %s%s\n",
        :ignored            => "\e[43m%9s\e[0m  %s%s\n",
        :skipped            => "\e[43m%9s\e[0m  %s%s\n",
        :success            => "\e[42m%9s\e[0m  %s%s\n",
        :failure            => "\e[41m%9s\e[0m  %s%s\n",
        :error              => "\e[37;40;1m%9s\e[0m  %s%s\n"  # ]]]]]]]]]]]]]]]]]]]] - bbedit hates open brackets...
      }
      StatusLabel = {
        :pending            => " Pending ",
        :manually_skipped   => " Skipped ",
        :dependency_missing => " Skipped ",
        :library_missing    => " Skipped ",
        :component_missing  => " Skipped ",
        :ignored            => " Skipped ",
        :skipped            => " Skipped ",
        :success            => " Success ",
        :failure            => " Failure ",
        :error              => "  Error  ",
      }
      Map = {
        :pending            => :incomplete,
        :manually_skipped   => :incomplete,
        :dependency_missing => :incomplete,
        :library_missing    => :incomplete,
        :component_missing  => :incomplete,
        :ignored            => :incomplete,
        :skipped            => :incomplete,
        :success            => :success,
        :failure            => :failure,
        :error              => :error,
      }
      FooterFormats = {
        :incomplete => "\e[43m%9s\e[0m\n",
        :success    => "\e[42m%9s\e[0m\n",
        :failure    => "\e[41m%9s\e[0m\n",
        :error      => "\e[37;40;1m%9s\e[0m\n"  # ]]]]]]]] - bbedit hates open brackets...
      }

      def run_all(*args)
        puts "Running all tests#{' verbosly' if $VERBOSE}"

        @depth    = 0
        @deferred = []
        start     = Time.now
        rv        = super # run all suites
        duration  = Time.now-start
        status    = global_status
        test, success, pending, manually_skipped, dependency_missing,
          library_missing, component_missing, ignored, skipped, failure, error =
          *@count.values_at(:test, :success, :pending, :manually_skipped,
                            :dependency_missing, :library_missing,
                            :component_missing, :ignored, :skipped, :failure,
                            :error)

        printf "\n%2$d tests run in %1$.1fs\n%3$d successful, %4$d pending, %5$d skipped, %6$d failures, %7$d errors\n",
          duration, test, success, pending, (skipped+manually_skipped+
          dependency_missing+library_missing+component_missing), failure, error
        print "Final status: "
        printf FooterFormats[Map[status]], StatusLabel[status]

        rv
      end

      def run_suite(suite)
        return super unless suite.description
        case size = suite.assertions.size
          when 0
            defer "\n           \e[1m#{'  '*@depth+suite.description}\e[0m"
          when 1
            defer "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (1 test)"
          else
            defer "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (#{size} tests)"
        end
        @depth += 1
        rv = super(suite) # run the suite
        pop_deferred
        @depth -= 1

        rv
      end

      def run_test(assertion, setup)
        clear_deferred
        rv        = super # run the assertion
        indent    = '           '+'  '*@depth
        backtrace = []
        reason    = rv.reason(:indent => indent)

        printf(Formats[rv.status], StatusLabel[rv.status], '  '*@depth, interpolated_description(assertion, setup))
        if rv.status == :error then
          backtrace = $VERBOSE ? rv.exception.backtrace : rv.exception.backtrace.first(1)
        elsif rv.status == :failure
          backtrace = ["#{assertion.file}:#{assertion.line}"]
        end
        puts reason if reason
        backtrace.each do |line| print(indent, '  ', line, "\n") end

        rv
      end

      def word_wrap(string, cols)
        str.scan(/[^ ]+ /)
      end

      def defer(output)
        @deferred << output
      end

      def pop_deferred
        @deferred.pop
      end

      def clear_deferred
        puts *@deferred unless @deferred.empty?
        @deferred.clear
      end
    end
  end

  @format["baretest/run/cli"] = Run::CLI # register the extender
end
