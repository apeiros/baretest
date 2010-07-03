#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  class Formatter

    # CLI runner is invoked with `-f cli` or `--format cli`.
    # It is intended for use with an interactive shell, to provide a comfortable, human
    # readable output.
    # It prints colored output (requires ANSI colors compatible terminal).
    #
    class CLI < Formatter
      Labels = {
        :pending => "\e[43m Pending \e[0m",
        :skipped => "\e[43m Skipped \e[0m",
        :success => "\e[42m Success \e[0m",
        :failure => "\e[41m Failure \e[0m",
        :error   => "\e[37;40;1m  Error  \e[0m"  # ]]]]]]]]]]]]]]]]]]]] - bbedit hates open brackets...
      }

      register 'baretest/formatter/cli'

      option_defaults :color   => true,
                      :profile => false

      text "Options for 'CLI' formatter:\n"

      option          :color,   '-c', '--[no-]color',   :Boolean, 'Enable/disable output coloring'
      option          :profile, '-p', '--[no-]profile', :Boolean, 'Enable/disable profiling assertions'

      text "\nEnvironment variables for 'CLI' formatter:\n"

      env_option      :color,   'COLOR'
      env_option      :profile, 'PROFILE'

      def start_all
        @insert_blank_line = false

        puts "Running tests in #{File.expand_path(Dir.getwd)}"
        puts "Using #{BareTest.ruby_description} with baretest #{BareTest::VERSION}"
        puts
      end

      def start_suite(suite)
        defer do
          puts if @insert_blank_line
          @insert_blank_line = false
          puts "          #{indent(suite, -1)}\e[1m#{suite.description}\e[0m" if suite.description
        end
      end

      def end_test(test, status, elapsed_time)
        apply_deferred
        @insert_blank_line = true

        puts "#{Labels[status.code]} #{indent(test, -1)}#{test.description}"
        case status.code
          when :pending, :skipped, :failure
            puts status.reason.gsub(/^/, "          #{indent(test)}")
          when :error
            indent = "          #{indent(test)}"
            puts status.reason.gsub(/^/, indent)
            puts backtrace(status).join("\n").gsub(/^/, indent)
          # no else needed, only :pending, :skipped, :failure and :error require additional output
        end
      end

      def end_suite(suite, *args)
        had_deferred = drop_last_deferred # append a line if nothing deferred had to be dropped (== there have been tests in the suite)
        if !had_deferred && @insert_blank_line then
          @insert_blank_line = false
          puts
        end
      end

      def end_all(status_collection, elapsed_time)
        success, pending, skipped, failure, error = *status_collection.values_at(:success, :pending, :skipped, :failure, :error)
        printf "0 #{Inflect['test'][0]} run in %.1fs\n", elapsed_time
        printf "%d %s, %d %s, %d %s, %d %s, %d %s\n",
          success, Inflect['success'][success],
          pending, Inflect['pending'][pending],
          skipped, Inflect['skipped'][skipped],
          failure, Inflect['failure'][failure],
          error,   Inflect['error'][error]
        printf "Final status: %s\n", Labels[status_collection.code]
      end
    end
  end
end
