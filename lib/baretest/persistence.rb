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

    # The directory this Persistence instance stores its data
    attr_reader :storage_dir

    # The directory of the project this Persistence instance is attached to
    attr_reader :project_dir

    # The id of the project this Persistence instance is attached to
    attr_reader :project_id

    def initialize(project_dir=nil, storage_dir=nil)
      @storage_dir = File.expand_path(storage_dir || self.class.storage_path)
      @project_dir = File.expand_path(project_dir || ".")
      @project_id  = self.class.determine_project_id(@project_dir)
    end

    # Stores data to a file.
    #
    # === Arguments
    # filename:: A relative path. Directories are created on the fly if
    #            necessary. Must not be an absolute path. The path is relative
    #            to Persistence#storage_dir
    # data::     The data to store. Anything that can be serialized by YAML.
    #            This excludes IOs and Procs.
    def store(filename, data)
      raise "Invalid filename: #{filename}" unless filename =~ %r{\A[A-Za-z0-9_-][A-Za-z0-9_-]*\z}
      dir = "#{@storage_dir}/#{@project_id}"
      FileUtils.mkdir_p(dir)
      File.open("#{dir}/#{filename}.yaml", "w") do |fh|
        fh.write(data.to_yaml)
      end
    end

    # Reads and deserializes the data in a given filename.
    # filename:: A relative path. Directories are created on the fly if
    #            necessary. Must not be an absolute path. The path is relative
    #            to Persistence#storage_dir
    # default::  The value to return in case the file does not exist.
    #            Alternatively you can pass a block that calculates the default.
    def read(filename, default=nil)
      raise "Invalid filename: #{filename}" if filename =~ %r{\A\.\./|/\.\./\z}
      path = "#{@storage_dir}/#{@project_id}/#{filename}.yaml"

      if File.exist?(path)
        YAML.load_file(path)
      elsif block_given?
        yield
      else
        default
      end
    end
  end
end
