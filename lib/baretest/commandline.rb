#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/assertion/context'
require 'baretest/assertion/failure'
require 'baretest/assertion/skip'



module BareTest

  # The CommandLine module provides all the functionality the
  # baretest executable uses in a programmatic way.
  # It in fact even is what the baretest executable itself uses.
  module CommandLine

    def load_formatter(format)
      require "baretest/run/#{format}" if String === format
      BareTest.format["baretest/run/#{format}"]
    end
    module_function :load_formatter

    # Run unit tests
    # * arguments: array of dirs/globs of files to load and run as tests
    # * options: a hash with options (all MUST be provided)
    #
    # :format      => String - the formatter
    # :interactive => Boolean - activate interactive mode (drops into irb on failure/error)
    # :verbose     => Boolean - provide verbose output
    def run(arguments, options)
      setup_path  = nil
      selectors   = BareTest.process_selectors(arguments)
      options     = selectors.merge(options)

      # Load the setup file, all helper files and all test files
      BareTest.load_standard_test_files(
        :verbose    => options[:verbose],
        :setup_path => options[:setup_path],
        :files      => options[:files],
        :chdir      => '.'
      )

      # Run the tests
      puts if options[:verbose]
      ARGV.clear # IRB is being stupid
      runner = BareTest::Run.new(BareTest.toplevel_suite, options)
      runner.run_all

      # Return whether all tests ran successful
      runner.global_status == :success
    end
    module_function :run

    def init(arguments, options)
      core = %w[
        test
        test/external
        test/helper
        test/helper/suite
        test/suite
      ]
      mirror = {
        'bin'  => %w[test/helper/suite test/suite],
        'lib'  => %w[test/helper/suite test/suite],
        'rake' => %w[test/helper/suite test/suite],
      }
      files = {
        'test/setup.rb' => <<-END_OF_SETUP.gsub(/^ {10}/, '')
          $LOAD_PATH.unshift(File.expand_path("\#{__FILE__}/../../lib")) # Add PROJECT/lib to $LOAD_PATH
        END_OF_SETUP
      }

      puts "Creating all directories and files needed in #{File.expand_path('.')}"
      core.each do |dir|
        if File.exist?(dir) then
          puts "Directory #{dir} exists already -- skipping"
        else
          puts "Creating #{dir}"
          Dir.mkdir(dir)
        end
      end
      mirror.each do |path, destinations|
        if File.exist?(path) then
          destinations.each do |destination|
            destination = File.join(destination,path)
            if File.exist?(destination) then
              puts "Mirror #{destination} of #{path} exists already -- skipping"
            else
              puts "Mirroring #{path} in #{destination}"
              Dir.mkdir(destination)
            end
          end
        end
      end
      files.each do |path, data|
        if File.exist?(path) then
          puts "File #{path} exists already -- skipping"
        else
          puts "Writing #{path}"
          File.open(path, 'wb') do |fh|
            fh.write(data)
          end
        end
      end
    end
    module_function :init

    def formats(arguments, options)
      puts "Available formats:"
      Dir.glob("{#{$LOAD_PATH.join(',')}}/baretest/run/*.rb") { |path|
        puts "- #{File.basename(path, '.rb')}"
      }
    end
    module_function :formats

    def commands(arguments, options)
      colors = $stdout.tty?

      description = <<-END_OF_DESCRIPTION.gsub(/^ {8}/, '') #                           |<- 80 cols ends here
        \e[1mCOMMANDS\e[0m

        The following commands are available in baretest:

        \e[1mcommands\e[0m
            List the available commands.

        \e[1menv\e[0m
            Show the baretest environment. This contains all data that influences
            baretests behaviour. That is: ruby version, ruby engine, determined
            test directory, stored data about this suite etc.

        \e[1mformats\e[0m
            Shows all formats available in \e[34mrun\e[0m's -f/--format option.

        \e[1mhelp\e[0m
            Provides help for all commands. Describes options, arguments and env
            variables each command accepts.

        \e[1minit\e[0m
            Create a basic skeleton of directories and files to contain baretests test-
            suite. Non-destructive (existing files won't be overriden or deleted).

        \e[1mrun\e[0m (default command)
            Run the tests and display information about them.

        \e[1mselectors\e[0m
            Detailed information about the selectors available to \e[34mrun\e[0m's
            arguments.

        \e[1mversion\e[0m
            Show the baretest executable and library versions.

      END_OF_DESCRIPTION
      #'#                                                                               |<- 80 cols ends here
      description.gsub!(/\e.*?m/, '') unless colors

      puts description
    end
    module_function :commands

    def selectors(arguments, options)
      colors = $stdout.tty?

      description = <<-END_OF_DESCRIPTION.gsub(/^ {8}/, '') #                           |<- 80 cols ends here
        \e[1mSELECTORS\e[0m

        \e[1mDescription\e[0m
            Selectors are used to identify what tests to run. Baretest knows 3 kinds of
            selectors: globs, tags and last-run-states. All of these can be preceeded with a
            minus sign (-), to negate the expression.
        
        \e[1mExample\e[0m
            `baretest test/suite -test/suite/foo @a -@b #failure -#pending`

            This will run all tests that
            * Are in the directory test/suite or any of its subdirectories
            * Are NOT in the directory test/suite/foo, or any of its subdirectories
            * Have the tag 'a'
            * Do NOT have the tag 'b'
            * Terminated with a failure status on the last run
            * Did NOT terminate with a pending status on the last run
        
        \e[1mGlobs\e[0m
            * '**' recursively matches all files and directories
            * '*' wildcard, matches any amount of any character
            * '?' wildcard, matches one character 
            * '{a,b,c}' alternation, matches any pattern in the comma separated list
            * Directories are equivalent to `directory/**/*` patterns

        \e[1mTags\e[0m
            Tags are preceeded with an @.

        \e[1mLast-run-status\e[0m
            Last run states are preceeded with a #.
            * #success, #failure, #error, #skipped, #pending
            * #error, #skipped and #pending are a subset of #failure
            * #pending is a subset of #skipped

      END_OF_DESCRIPTION

      description.gsub!(/\e.*?m/, '') unless colors

      puts description
    end
    module_function :selectors

    def env(arguments, options)
      puts "Versions:",
           "* executable: #{Version}",
           "* library: #{BareTest::VERSION}",
           "* ruby #{RUBY_VERSION}",
           ""
    end
    module_function :env

    def version(arguments, options)
      puts "baretest executable version #{Version}",
           "library version #{BareTest::VERSION}",
           "ruby version #{RUBY_VERSION}",
           ""
    end
    module_function :version
  end
end
