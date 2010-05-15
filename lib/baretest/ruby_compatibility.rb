#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
# TODO: check license for instance_exec and amend
#++



unless Array.method_defined? :find_index
  class Array
    def find_index
      each_with_index do |obj, index|
        return index if yield(obj)
      end
      nil
    end
  end
end

unless Object.method_defined?(:instance_exec)
  class Object
    module InstanceExecMethods #:nodoc:
    end

    include InstanceExecMethods

    # Evaluate the block with the given arguments within the context of
    # this object, so self is set to the method receiver.
    #
    # From Mauricio's http://eigenclass.org/hiki/bounded+space+instance_exec
    #
    # This version has been borrowed from Rails for compatibility sake.
    def instance_exec(*args, &block)
      begin
        old_critical, Thread.critical = Thread.critical, true
        n = object_id
        n += 1 while respond_to?(method_name = "__instance_exec#{n}")
        InstanceExecMethods.module_eval { define_method(method_name, &block) }
      ensure
        Thread.critical = old_critical
      end

      begin
        send(method_name, *args)
      ensure
        InstanceExecMethods.module_eval { remove_method(method_name) } rescue nil
      end
    end
  end
end
