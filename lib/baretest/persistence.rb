#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/uid'
require 'yaml'
require 'fileutils'



module BareTest

  # A simple file based storage. This is used to persist data between runs
  # of baretest (caching data, keeping the last run's states for filtering,
  # etc.)
  # The data is stored in ~/.baretest, per project. A file with the name pattern
  #
  class Persistence

    # The default storage path base (~/.baretest)
    def self.storage_path
      File.expand_path('~/.baretest')
    end

    # BareTest uses a file of the form '.baretest_id_*' (where * is a 32 digits
    # long hex) to uniquely identify a project. This ID is then used to
    # associate stored data with the project.
    def self.determine_project_id(project_dir)
      found = Dir.glob("#{project_dir}/.baretest_id_*") { |path|
        break $1 if File.file?(path) && path =~ /id_([A-Fa-f0-9]{32})$/
      }
      unless found then
        found = UID.hex_uid
        File.open(".baretest_id_#{found}", "w") { |fh|
          # The content of this file is irrelevant, only its name. So lets
          # add a little bit of explaining text in case somebody wonders about
          # the purpose of this file.
          fh.write(
            "This file is used by baretest to find the persisted data in your ~/.baretest directory.\n" \
            "Deleting this file will result in orphaned persistence data.\n" \
            "See `baretest help reset`."
          )
        }
      end

      found
    end

    # The directory this Persistence instance stores its data
    attr_reader :storage_dir

    # The directory of the project this Persistence instance is attached to
    attr_reader :project_dir

    # The id of the project this Persistence instance is attached to
    attr_reader :project_id

    # Arguments:
    # project_dir:: The directory of the project
    # storage_dir:: The directory where this Persistence instance should store
    #               its data
    def initialize(project_dir=nil, storage_dir=nil)
      @storage_dir = File.expand_path(storage_dir || self.class.storage_path)
      @project_dir = File.expand_path(project_dir || ".")
      @project_id  = self.class.determine_project_id(@project_dir)
      stat         = File.stat(@project_dir)
      store('project', {
        :project_directory        => @project_dir,
        :project_directory_inode  => stat.ino,
        :project_directory_device => stat.dev
      })
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

    # Deletes the file for the given filename.
    # filename:: A relative path. Empty directories are recursively deleted
    #            up to (but without) Persistence#storage_dir. The path is
    #            relative to Persistence#storage_dir
    def delete(filename)
      raise "Invalid filename: #{filename}" if filename =~ %r{\A\.\./|/\.\./\z}
      project_storage_dir = "#{@storage_dir}/#{@project_id}"
      path                = "#{project_storage_dir}/#{filename}.yaml"

      File.delete(path)
      container = File.dirname(path)
      while container != project_storage_dir
        begin
          Dir.delete(container)
        rescue Errno::ENOTEMPTY
          break
        else
          container = File.dirname(container)
        end
      end
    end

    # Remove all files that store state, cache things etc.
    def clear
      delete('final_states')
    end

  private
    def assert_valid_filename(filename)
    end
  end
end
