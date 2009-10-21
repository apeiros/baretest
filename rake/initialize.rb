#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'pp'
$LOAD_PATH.unshift(File.expand_path("#{__FILE__}/../../lib")) # <project-dir>/lib
$LOAD_PATH.unshift(File.expand_path("#{__FILE__}/../lib"))    # <project-dir>/rake/lib

begin; require 'rubygems'; rescue LoadError; end
require 'silverplatter/project/description'
require 'silverplatter/project/version'
require 'silverplatter/project/bonesplitter'

include BoneSplitter

REQUIRED_RAKE_VERSION = "0.8"
abort("Requires rake version #{REQUIRED_RAKE_VERSION}") unless has_version?(RAKEVERSION, REQUIRED_RAKE_VERSION)

# bonesplitter requires a Markdown constant
Markdown = case
  when lib?('maruku') then Maruku
  when lib?('markdown') then Markdown
  when lib?('rdiscount') then RDiscount
  else nil
end
has_lib!('markdown') if Markdown # fake it

Project = SilverPlatter::Project::Description.new


# Gem Packaging
Project.gem = SilverPlatter::Project::Description.new({
  :dependencies => nil,
  :executables  => FileList['bin/**'],
  :extensions   => FileList['ext/**/extconf.rb'],
  :files        => nil,
  :has_rdoc     => true,
  :need_tar     => true,
  :need_zip     => false,
  :extras       => {},
})

# Data about the project itself
Project.meta = SilverPlatter::Project::Description.new({
  :name             => nil,
  :version          => nil,
  :author           => "Stefan Rusterholz",
  :email            => "stefan.rusterholz@gmail.com",
  :summary          => nil,
  :website          => nil,
  :bugtracker       => nil,
  :feature_requests => nil,
  :irc              => "irc://freenode.org/#silverplatter",
  :release_notes    => "NEWS.markdown",
  :changelog        => "CHANGELOG.markdown",
  :todo             => "TODO.markdown",
  :readme           => "README.markdown",
  :manifest         => "MANIFEST.txt",
  :gem_host         => :rubyforge,
  :configurations   => "~/Library/Application Support/Bonesplitter",
})

# Manifest
Project.manifest = SilverPlatter::Project::Description.new({
  :ignore     => nil,
})

# File Annotations
Project.notes = SilverPlatter::Project::Description.new({
  :include    => %w[lib/**/*.rb {bin,ext}/**/*], # NOTE: use post_load and set to manifest()?
  :exclude    => %w[],
  :tags       => %w[FIXME OPTIMIZE TODO],
})

# Rcov
Project.rcov = SilverPlatter::Project::Description.new({
  :dir             => 'coverage',
  :opts            => %w[--sort coverage -T],
  :threshold       => 100.0,
  :threshold_exact => false,
})

# Rdoc
Project.rdoc = SilverPlatter::Project::Description.new({
  :options    => %w[
                   --inline-source
                   --line-numbers
                   --charset utf-8
                   --tab-width 2
                 ],
  :include    => %w[{lib,bin,ext}/**/* *.{txt,markdown,rdoc}], # globs
  :exclude    => %w[**/*/extconf.rb Manifest.txt],             # globs
  :main       => nil,                                          # path
  :output_dir => 'docs',                                       # path
  :remote_dir => 'docs',
  #:template   => lib?(:allison) && Gem.searcher.find("allison").full_gem_path+"/lib/allison",
  # 'Allison gem, tasks: doc:html, creates nicer html rdoc output'
})

# Rubyforge
Project.rubyforge = SilverPlatter::Project::Description.new({
  :project    => nil, # The rubyforge projectname
})

# Specs (bacon)
Project.rubyforge = SilverPlatter::Project::Description.new({
  :files => FileList['spec/**/*_spec.rb'],
  :opts  => []
})

# Load the other rake files in the tasks folder
rakefiles = Dir.glob('rake/tasks/*.rake').sort
rakefiles.unshift(rakefiles.delete('rake/tasks/post_load.rake')).compact!
import(*rakefiles)
