#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/uid'
require 'yaml'
require 'fileutils'



module BareTest

  class Persistence
    def self.storage_path
      File.expand_path('~/.baretest')
    end

    def self.determine_project_id(project_dir)
      found = Dir.glob("#{project_dir}/.baretest_id_*") { |path|
        break $1 if File.file?(path) && path =~ /id_([A-Fa-f0-9]{32})$/
      }
      unless found then
        found = UID.hex_uid
        File.open(".baretest_id_#{found}", "w") {} # no File::touch, evil
      end

      found
    end

    def initialize(project_dir=nil, storage_dir=nil)
      @storage_dir = File.expand_path(storage_dir || self.class.storage_path)
      @project_dir = File.expand_path(project_dir || ".")
      @project_id  = self.class.determine_project_id(@project_dir)
    end

    def store(filename, data)
      raise "Invalid filename: #{filename}" unless filename =~ /[A-Za-z0-9_-]+/
      dir = "#{@storage_dir}/#{@project_id}"
      FileUtils.mkdir_p(dir)
      File.open("#{dir}/#{filename}.yaml", "w") do |fh|
        fh.write(data.to_yaml)
      end
    end

    def read(filename)
      path = "#{@storage_dir}/#{@project_id}/#{filename}.yaml"
      File.exist?(path) ? YAML.load_file(path) : nil
    end
  end
end
