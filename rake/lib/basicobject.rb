#--
# Copyright 2004 by Jim Weirich (jim@weirichhouse.org).
# All rights reserved.

# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work as long as the
# above copyright notice is included.
#
# The code below is derived from Jim Weirichs BlankSlate
#++
unless Object.const_defined?(:BasicObject)
  class BasicObject
    public_instance_methods(true).each { |name|
      if public_instance_methods(true).include?(name) && name !~ /^__/ then
        undef_method name
      end
    }

    def inspect
      classname = Object.instance_method(:class).bind(self).call
      object_id = Object.instance_method(:object_id).bind(self).call
      Kernel.sprintf("#<%s:0x%x>", classname, object_id<<1)
    end
  end

  class Object #:nodoc:
    class << self
      alias basic_object_method_added method_added

      # Detect method additions to Object and remove them in the
      # BasicObject class.
      def method_added(name) # :nodoc:
        basic_object_method_added(name)
        return unless BasicObject.ancestors.include?(self)
        if BasicObject.public_instance_methods(true).include?(name.to_s) && name !~ /^__|instance_eval$/ then
          BasicObject.__send__(:undef_method, name)
        end
      end
    end
  end

  class Module
    alias basic_object_append_features append_features
    def append_features(mod)
      basic_object_append_features(mod)
      return unless BasicObject.ancestors.include?(self)
      mod.public_instance_methods(true).each do |name|
        if BasicObject.public_instance_methods(true).include?(name) && name !~ /^__|instance_eval$/ then
          BasicObject.__send__(:undef_method, name)
        end
      end
    end
  end
end
