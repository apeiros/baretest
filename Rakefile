# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

require 'rake/initialize'

task :default => 'test'



# Project details (defaults are in rake/initialize, some cleanup is done per section in the
# task 'prerequisite' in each .task file. Further cleanup is done in post_load.rake)
Project.meta.name             = 'baretest'
Project.meta.version          = version_proc("BareTest::VERSION")
Project.meta.readme           = 'README.rdoc'
Project.meta.summary          = extract_summary()
Project.meta.description      = extract_description()
Project.meta.website          = 'http://baretest.rubyforge.org'
Project.meta.bugtracker       = 'http://projects.sr.brightlight.ch/projects/baretest/issues'
Project.meta.feature_requests = 'http://projects.sr.brightlight.ch/projects/baretest/issues'
Project.meta.use_git          = true

Project.manifest.ignore       = %w[
                                    Rakefile
                                    baretest.bbprojectd/**/*
                                    baretest.gemspec
                                    dev/**/*
                                    doc/announcements/**/*
                                    docs/**/*
                                    lib/baretest/safe.rb
                                    pkg/**/*
                                    rake/**/*
                                    web/**/*
                                    ydocs/**/*
                                ]

Project.rubyforge.project     = 'baretest'
Project.rubyforge.path        = 'baretest'

Project.rdoc.include         << 'doc/*.rdoc'
