#!/usr/bin/env ruby

#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



Version = "0.4.0" # Executable version



begin
  # if baretest is installed as a gem, the executable is be wrapped by rubgems anyway, so we don't
  # need to require rubygems ourself.
  require 'command'
  require 'baretest'
rescue LoadError
  # assume baretest is not installed and this is a cold-run from source
  $LOAD_PATH.unshift(File.expand_path("#{__FILE__}/../../lib"))
  require 'command'
  require 'baretest'
end



# Specify commands and options
Command "run" do
  # global arguments
  argument :command, '[command]', :Virtual, "The command to run. See `baretest commands`"
  argument :options, '[options]', :Virtual, "The flags and options, see in the \"Options\" section."

  # global options
  o :commands,    nil,  '--commands', :Boolean, "overview over the commands"
  o :help,        '-h', '--help',     :Boolean, "help for usage and flags"
  o :version,     '-v', '--version',  :Boolean, "print the version and exit"

  # specify the 'run' command, its default options, its options and helptext
  command "run", :format => 'cli', :interactive => false, :verbose => false do
    usage

    argument :command
    argument :options
    argument '*glob', File, "The testfiles to run.\n" \
                            "Defaults to 'test/{suite,unit,integration,system}/**/*.rb'\n" \
                            "Providing a directory is equivalent to dir/**/*.rb"

    text "\nDefault command is 'run', which runs the testsuite or the provided testfiles.\n\nOptions:\n"

    o :commands
    o :debug,       '-d', '--debug',         :Boolean, "set debugging flags (set $DEBUG to true)"
    o :interactive, '-i', '--interactive',   :Boolean, "drop into IRB on error or failure"
    o :format,      '-f', '--format FORMAT', :String,  "use FORMAT for output, see `baretest formats`"
    o :setup_file,  '-s', '--setup FILE',    :File,    "specify setup file"
    o :verbose,     '-w', '--warn',          :Boolean, "turn warnings on for your script"
    o :help
    o :version

    text ""

    placeholder :format_options

    text "\nEnvironment variables:\n"

    env_option :format,      'FORMAT'
    env_option :verbose,     'VERBOSE'
    env_option :interactive, 'INTERACTIVE'
  end

  command "init" do
    text '  Create the necessary directories and files'
    o :help
  end

  command "formats"
  command "env"
  command "version"
  command "commands"
  command "help"
end



# Execute command
Command.with(ARGV) do
  # parse out the command
  command = command!
  # parse all options we know about and leave alone those we don't
  options = options! :ignore_invalid_options

  # some options are equivalent to commands - if they are set, change the
  # command
  if set = [:help, :commands].find { |flag| options[flag] } then
    command = set
  end
  if %w[run help].include?(command) then
    BareTest::CommandLine.load_formatter(options[:format])
  end

  options = options! # reparse with new information

  case command
    when "run" # run the testsuite/-file
      BareTest::CommandLine.run(options)
    when "init" # create the test directory
      BareTest::CommandLine.init(options)
    when "formats" # list available formats
      BareTest::CommandLine.formats(options)
    when "env" # show information about baretest (config, version, paths, ...)
      BareTest::CommandLine.env(options)
    when "version" # show version information about baretest
      puts "baretest executable version #{Version}",
           "library version #{BareTest::VERSION}",
           "ruby version #{RUBY_VERSION}",
           ""
    when "commands"
      print_commands
    when "help"
      print_help(command)
  end
end
