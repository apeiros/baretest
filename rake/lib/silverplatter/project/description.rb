#--
# Copyright 2007-2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'basicobject' # pre ruby 1.9

module SilverPlatter
  class Project

    # This class is not written for long running scripts as it leaks symbols.
    # It is openstructlike, but a bit more lightweight and blankslate so about any method
    # will work.
    # You can set values to procs and call __finalize__ to get them replaced by the value
    # returned by the proc.
    #
    class Description < BasicObject
      attr_reader :__hash__

      def initialize(values=nil, &block)
        @__hash__ = values || {}
        Object.instance_method(:instance_eval).bind(self).call(&block) if block
      end

      def [](key)
        @__hash__[key.to_sym]
      end

      def []=(key,value)
        @__hash__[key.to_sym] = value
      end

      def delete!(key)
        @__hash__.delete(key.to_sym)
      end

      # All values that respond to .call are replaced by the value
      # returned when calling.
      def __finalize__
        @__hash__.each do |k,v|
          @__hash__[k] = v.call if v.respond_to?(:call)
        end
        self
      end

      def inspect
        classname = Object.instance_method(:class).bind(self).call
        object_id = Object.instance_method(:object_id).bind(self).call
        sprintf "<%s:0x%x %p>", classname, object_id, @__hash__
      end

      def method_missing(name, *args)
        case args.length
          when 0 # getter
            if key = name.to_s[/^(.*)\?$/, 1] then
              !!@__hash__[key.to_sym] # booleanize
            else
              @__hash__[name]
            end
          when 1 # setter
            if key = name.to_s[/^(\w+)=?$/, 1] then
              @__hash__[key.to_sym] = args.first
            else
              super
            end
          else
            super
        end
      end
    end
  end
end