# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

require 'rake/initialize'

task :default => 'test:run'



# Project details (defaults are in rake/initialize, some cleanup is done per section in the
# task 'prerequisite' in each .task file. Further cleanup is done in post_load.rake)
Project.meta.name             = 'baretest'
Project.meta.version          = version_proc("Test::VERSION")
p :summary => (Project.meta.summary          = extract_summary())
Project.meta.website          = 'http://'
Project.meta.bugtracker       = 'http://'
Project.meta.feature_requests = 'http://'
Project.meta.use_git          = true

Project.manifest.ignore       = %w[web/**/*]

Project.rubyforge.project     = 'baretest'
Project.rubyforge.path        = 'baretest'
