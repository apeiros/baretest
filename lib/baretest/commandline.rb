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
      files       = arguments.empty? ? nil : arguments # (ARGV.empty? ? nil : ARGV)

      # Load the setup file, all helper files and all test files
      BareTest.load_standard_test_files(
        :verbose    => options[:verbose],
        :setup_path => options[:setup_path],
        :files      => files,
        :chdir      => '.'
      )

      # Run the tests
      puts if options[:verbose]
      ARGV.clear # IRB is being stupid
      BareTest.run(options).global_status == :success
    end
    module_function :run

    def init *a
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
        'test/setup.rb' => <<-END_OF_SETUP.gsub(/^ {8}/, '')
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

    def formats *a
      puts "Available formats:"
      Dir.glob("{#{$LOAD_PATH.join(',')}}/baretest/run/*.rb") { |path|
        puts "- #{File.basename(path, '.rb')}"
      }
      exit
    end
    module_function :formats

    def env *a
      puts "Versions:",
           "* executable: #{Version}",
           "* library: #{BareTest::VERSION}",
           "* ruby #{RUBY_VERSION}",
           ""
    end
    module_function :env

    def version *a
      puts "baretest executable version #{Version}",
           "library version #{BareTest::VERSION}",
           "ruby version #{RUBY_VERSION}",
           ""
    end
    module_function :version
  end
end
