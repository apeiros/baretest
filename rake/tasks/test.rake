#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# This rake task collects some ENV variables and then delegates to duty to
# BareTest::CommandLine#run

namespace :test do
  desc "Information about how your test directory should look."
  task :structure do
    project_dir = File.expand_path(Dir.getwd)

    puts "rake test:run expects to the directory test (#{File.expand_path(project_dir)}/test) to exist."
  end

  desc "Run testsuite. Set FORMAT env variable to change the formatter used, INTERACTIVE to 'true' to have irb mode."
  task :run do
    begin
      require 'baretest'
    rescue LoadError => e
      puts "Could not run tests: #{e}"
    else
      # Options can only be supplied via ENV
      options     = {
        :format      => (ENV["FORMAT"] || 'cli'),
        :interactive => (ENV["INTERACTIVE"] =~ /^[ty]/i), # true, TRUE, yes, YES or abbreviated
      }

      # Run all tests
      BareTest::CommandLine.run([], options)
    end
  end
end

desc 'Alias for test:run'
task :test => 'test:run'
