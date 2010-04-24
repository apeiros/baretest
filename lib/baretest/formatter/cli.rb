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
      register 'baretest/formatter/cli'

      option_defaults :color   => true,
                      :profile => false

      text "Options for 'CLI' formatter:\n"

      option          :color,   '-c', '--[no-]color',   :Boolean, 'Enable/disable output coloring'
      option          :profile, '-p', '--[no-]profile', :Boolean, 'Enable/disable profiling assertions'

      text "\nEnvironment variables for 'CLI' formatter:\n"

      env_option      :color,   'COLOR'
      env_option      :profile, 'PROFILE'

      def start_suite(suite)
        puts "             #{indent(suite)}#{suite.description}"
      end

      def end_test(test, status)
        puts " [#{status.to_s.center(9)}] #{indent(test)}#{test.description.join(' ')}"
      end
    end
  end
end
