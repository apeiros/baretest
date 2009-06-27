#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# This rake task expects to be in PROJECT_DIR/tasks/test.rake
# It assumes that the tests are in PROJECT_DIR/test/**/*.rb
# This is relevant as it calculates the paths accordingly.
# Additionally it will add PROJECT_DIR/lib - if present - to $LOAD_PATH.

desc "Run testsuite. Set FORMAT env variable to change the formatter used."
task :test do
  begin
    require 'test'
  rescue LoadError => e
    puts "Could not run tests: #{e}"
  else
    # Prepare paths
    rake_file = File.expand_path(__FILE__)
    test_dir  = [File.expand_path("#{rake_file}/../../test"), File.expand_path('./test')].find { |path|
      File.directory?(path)
    }
    lib_dir   = File.expand_path("#{rake_file}/../../lib")

    # Verify that the test directory exists
    raise "Could not determine test directory, please adapt this rake task to " \
          "your directory structure first." unless test_dir

    # Add PROJECT_DIR/lib to $LOAD_PATH if the dir exists
    if File.directory?(lib_dir) && !$LOAD_PATH.include?(lib_dir) then
      $LOAD_PATH.unshift(lib_dir)
      puts "Added '#{lib_dir}' to $LOAD_PATH" if $VERBOSE
    end

    # Load all test definitions
    setup_path ||= "#{test_dir}/setup.rb"
    load(setup_path) if File.exist?(setup_path)
    Dir.glob("#{test_dir}/lib/**/*.rb") { |path|
      helper_path = path.sub(%r{^(#{Regexp.escape(test_dir)})/lib/}, '\1/helper/')
      puts "Loading helper file #{helper_path}" if $VERBOSE
      load(helper_path) if File.exist?(helper_path)
      puts "Loading test file #{path}" if $VERBOSE
      load(path)
    }

    # Run all tests
    format      = ENV["FORMAT"] || 'cli'
    interactive = ENV["INTERACTIVE"] == 'true'
    Test.run(:format => format, :interactive => interactive)
  end
end
