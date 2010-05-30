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

    # Improved version of Mauricio's implementation on
    # http://eigenclass.org/hiki/bounded+space+instance_exec
    # Should be faster for recursive instance_exec's and doesn't interrupt the
    # scheduler
    def instance_exec(*args, &block)
      current_thread = Thread.current
      method_number  = current_thread[:instance_exec_method_number]
      if method_number then
        current_thread[:instance_exec_method_number] = method_number+1
      else
        method_number = 0
        current_thread[:instance_exec_method_number] = 1
      end
      method_name    = "__instance_exec_#{current_thread.object_id}_#{method_number}"

      InstanceExecMethods.send(:define_method, method_name, &block)

      begin
        send(method_name, *args)
      ensure
        InstanceExecMethods.send(:remove_method, method_name) rescue nil
      end
    end
  end
end
