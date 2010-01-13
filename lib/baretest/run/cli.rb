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
      Formats = {
        :pending => "\e[43m%9s\e[0m  %s%s\n",
        :skipped => "\e[43m%9s\e[0m  %s%s\n",
        :success => "\e[42m%9s\e[0m  %s%s\n",
        :failure => "\e[41m%9s\e[0m  %s%s\n",
        :error   => "\e[37;40;1m%9s\e[0m  %s%s\n"  # ]]]]]]]] - bbedit hates open brackets...
      }

      FooterFormats = {
        :incomplete => "\e[43m%9s\e[0m\n",
        :success    => "\e[42m%9s\e[0m\n",
        :failure    => "\e[41m%9s\e[0m\n",
        :error      => "\e[37;40;1m%9s\e[0m\n"  # ]]]]]]]] - bbedit hates open brackets...
      }

      def run_all(*args)
        @depth = 0
        puts "Running all tests#{' verbosly' if $VERBOSE}"
        start = Time.now
        super # run all suites
        status = global_status
        printf "\n%2$d tests run in %1$.1fs\n%3$d successful, %4$d pending, %5$d failures, %6$d errors\n",
          Time.now-start, *@count.values_at(:test, :success, :pending, :failure, :error)
        print "Final status: "
        printf FooterFormats[status], status_label(status)
      end

      def run_suite(suite)
        return super unless suite.description
        skipped = suite.skipped.size
        case size = suite.assertions.size
          when 0
            if skipped.zero? then
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m"
            else
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (#{skipped} skipped)"
            end
          when 1
            if skipped.zero? then
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (1 test)"
            else
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (1 test/#{skipped} skipped)"
            end
          else
            if skipped.zero? then
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (#{size} tests)"
            else
              puts "\n           \e[1m#{'  '*@depth+suite.description}\e[0m (#{size} tests/#{skipped} skipped)"
            end
        end
        @depth += 1
        super(suite) # run the suite
        @depth -= 1
      end

      def run_test(assertion, setup)
        rv               = super # run the assertion
        indent           = '           '+'  '*@depth
        message          = []
        deeper           = []

        printf(Formats[rv.status], status_label(rv.status), '  '*@depth, rv.interpolated_description)
        if rv.status == :error then
          message = (rv.exception.message || "no error message given").split("\n")
          deeper  = $VERBOSE ? rv.exception.backtrace : rv.exception.backtrace.first(1)
        elsif rv.status == :failure
          message = (rv.reason || "no failure reason given").split("\n")
          deeper  = ["#{rv.file}:#{rv.line}"]
        end
        message.each do |line| print(indent, line, "\n") end
        deeper.each do |line| print(indent, '  ', line, "\n") end

        rv
      end

      def word_wrap(string, cols)
        str.scan(/[^ ]+ /)
      end

      def status_label(status)
        status.to_s.capitalize.center(9)
      end
    end
  end

  @format["baretest/run/cli"] = Run::CLI # register the extender
end
