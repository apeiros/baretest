#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



class <<self
  # This method is only and only available on toplevel, enabling to use suite
  # on toplevel too to define the toplevel suite, without polluting neither
  # Kernel nor Object
  def suite(*args, &block) # :nodoc:
    BareTest.suite(*args, &block)
  end
  private :suite
end



module Kernel
  # Execute a piece of code in the context of BareTest
  def BareTest(&block)
    BareTest.instance_eval(&block)
  end
  module_function :BareTest



  # All extensions Kernel#require_path and Kernel#expanded_require_path will try
  # for a given filename
  RequireExtensions = %w[.rb .so .dll .bundle .dylib]

  # Returns the path to the file require would load, also see Kernel#expanded_require_path
  def require_path(name, extensions=nil)
    extensions = (extensions || ::Kernel::RequireExtensions).join(',')
    Dir.glob("{#{$LOAD_PATH.join(',')}}/#{name}{#{extensions}}") { |path|
      return path
    }
    nil
  end

  # Returns the absolute path to the file require would load, also see Kernel#require_path
  def expanded_require_path(name, extensions=nil)
    path = require_path(name, extensions)
    path && File.expand_path(path)
  end

  # Will load the given file like load (but accepts files without .rb in the end, like require),
  # but evaluate it into the module given with the second arg (defaulting to Module.new).
  # It uses Kernel#expanded_require_path with '' and '.rb' as extensions to determine the file to
  # load uses the returned path for error messages (second argument to Module#modul_eval).
  def load_into(name, mod=nil)
    mod ||= Module.new
    path  = expanded_require_path(name, ['', '.rb'])
    raise LoadError, "No such file to load -- #{name}" unless path
    mod.module_eval(File.read(path), path)

    mod
  end

  module_function :require_path, :expanded_require_path, :load_into
end
