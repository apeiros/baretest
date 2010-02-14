#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  # Extend Formatters that have custom options with this module to gain
  # convenience methods to define the custom options.
  # See Command's documentation for more information.
  module Formatter

    # Invoke Formatter#initialize_options
    def self.extended(obj) # :nodoc:
      obj.initialize_options
    end

    # Provides access to the command/options/arguments related information.
    attr_reader :command

    # Initialize some instance variables needed for the DSL.
    def initialize_options # :nodoc:
      @command = {
        :option_defaults => {},
        :elements        => [],
      }
    end

    # Define default values for options.
    # Example:
    #   option_defaults :colors => false,
    #                   :indent => 3
    def option_defaults(defaults={})
      @command[:option_defaults].update(defaults)
    end

    # Inject a piece of text into the helptext.
    def text(*args)
      @command[:elements] << [:text, args]
    end

    # Use an env-variable and map it to an option.
    # Example:
    #   env_option :indent, "INDENT"
    def env_option(*args)
      @command[:elements] << [:env_option, args]
    end

    # Define a formatter-specific option.
    # See Command::Definition#option
    def option(*args)
      @command[:elements] << [:option, args]
    end
  end
end
