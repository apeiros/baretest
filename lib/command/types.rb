#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Command
  Types = {
    :Virtual   => nil,
    :Boolean   => proc { |v| v =~ /\A(?:true|y(?:es)?)\z/i },
    :String    => proc { |v| v },
    :Integer   => proc { |v| Integer(v) },
    :Octal     => proc { |v| Intever("0#{v}") },
    :Hex       => proc { |v| Integer("0x#{v}") },
    :Float     => proc { |v| Float(v) },
    :File      => proc { |v|
      raise FileNotFoundError, "No such file or directory - #{v}" unless File.exist?(v)
      raise NoFileError, "Not a file - #{v}" unless File.file?(v)
      v
    },
    :Directory => proc { |v|
      raise DirectoryNotFoundError, "No such file or directory - #{v}" unless File.exist?(v)
      raise NoDirectoryError, "Not a directory - #{v}" unless File.directory?(v)
      v
    },
    :Path => proc { |v|
      require 'pathname'
      Pathname.new(v)
    }
  }
end
