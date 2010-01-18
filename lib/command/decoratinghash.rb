#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Command
  class DecoratingHash < Hash
    attr_accessor :target

    def self.new(target)
      obj = super() do |h,k| h.target && h.target[k] end
      obj.target = target
      obj
    end

    alias own_size size unless method_defined? :own_size
    alias own_length own_size

    def size
      @target ? keys.size : super
    end
    alias length size

    def keys
      @target ? (super | @target.keys) : super
    end
  end
end
