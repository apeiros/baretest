#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# This rake task expects to be in PROJECT_DIR/tasks/test.rake
# It assumes that the tests are in PROJECT_DIR/test/**/*.rb
# This is relevant as it calculates the paths accordingly.
# It uses BareTest.load_standard_test_files to load setup and test files.
# This means it will also load a test/setup.rb file if present, where
# you can add paths to $LOAD_PATH.

namespace :test do
  desc "Information about how your test directory should look."
  task :structure do
    wd        = File.expand_path(Dir.getwd)
    rake_file = File.expand_path(__FILE__)
    test_dir  = ['./test', "#{rake_file}/../../test"].map { |path|
      full     = File.expand_path(path)
      relative = full[(wd.size+1)..-1]
      "* #{relative} (#{full})"
    }

    puts "rake test:run expects to find one of the these directories:", *test_dir
  end

  desc "Run testsuite. Set FORMAT env variable to change the formatter used, INTERACTIVE to have irb mode."
  task :run do
    begin
      require 'baretest'
    rescue LoadError => e
      puts "Could not run tests: #{e}"
    else
      # Prepare paths
      rake_file = File.expand_path(__FILE__)
      test_dir  = ["#{rake_file}/../../test", './test'].map { |path|
        File.expand_path(path)
      }.find { |path|
        File.directory?(path)
      }

      # Verify that the test directory exists
      raise "Could not determine test directory, please adapt this rake task to " \
            "your directory structure first (see rake test:structure)." unless test_dir

      # Load all test definitions
      BareTest.load_standard_test_files(
        :verbose    => $VERBOSE,
        :setup_file => 'test/setup.rb',
        :chdir      => File.dirname(test_dir) # must chdir to 1 above the 'test' dir
      )

      # Run all tests
      format      = ENV["FORMAT"] || 'cli'
      interactive = ENV["INTERACTIVE"] == 'true'
      BareTest.run(:format => format, :interactive => interactive)
    end
  end
end

desc 'Alias for test:run'
task :test => 'test:run'