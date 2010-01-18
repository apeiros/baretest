#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  module Formatter
    def self.extended(obj)
      obj.initialize_options
    end

    attr_reader :command

    def initialize_options
      @command = {
        :option_defaults => {},
        :elements        => [],
      }
    end

    def option_defaults(defaults={})
      @command[:option_defaults].update(defaults)
    end

    def text(*args)
      @command[:elements] << [:text, args]
    end

    def env_option(*args)
      @command[:elements] << [:env_option, args]
    end

    def option(*args)
      @command[:elements] << [:option, args]
    end
  end
end
