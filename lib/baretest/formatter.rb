#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  # Extend Formatters that have custom options with this module to gain
  # convenience methods to define the custom options.
  # See Command's documentation for more information.
  class Formatter
    @classes = {}
    class <<self; attr_reader :classes; end

    # Invoke Formatter#initialize_options
    def self.inherited(obj) # :nodoc:
      obj.initialize_options
    end

    # Provides access to the command/options/arguments related information.
    attr_reader :command

    # Initialize some instance variables needed for the DSL.
    def self.initialize_options # :nodoc:
      @command = {
        :option_defaults => {},
        :elements        => [],
      }
    end

    def self.register(path)
      Formatter.classes[self] = path
    end

    # Define default values for options.
    # Example:
    #   option_defaults :colors => false,
    #                   :indent => 3
    def self.option_defaults(defaults={})
      @command[:option_defaults].update(defaults)
    end

    # Inject a piece of text into the helptext.
    def self.text(*args)
      @command[:elements] << [:text, args]
    end

    # Use an env-variable and map it to an option.
    # Example:
    #   env_option :indent, "INDENT"
    def self.env_option(*args)
      @command[:elements] << [:env_option, args]
    end

    # Define a formatter-specific option.
    # See Command::Definition#option
    def self.option(*args)
      @command[:elements] << [:option, args]
    end

    def initialize(output_device)
      @output_device     = output_device
      @interactive       = @output_device.tty? rescue false
      @auto_strip_colors = !@interactive
      @deferred          = []
      @indent_string     = '  '
    end

    def puts(*args)
      @output_device.puts(auto_strip_colors(*args))
    end

    def print(*args)
      @output_device.print(auto_strip_colors(*args))
    end

    def printf(*args)
      @output_device.printf(auto_strip_colors(*args))
    end

    def auto_strip_colors(*args)
      return args unless @auto_strip_colors
      args.map { |arg| arg.gsub(/\e\[[^m]*m/, '') }
    end

    def indent(item)
      @indent_string*item.nesting_level
    end

    # Add data to output, but mark it as deferred
    # We defer in order to be able to ignore suites. Ignored suites that
    # contain unignored suites/assertions must be displayed, ignored suites
    # that don't, will be popped from the deferred-stack
    def defer(&block)
      @deferred << block
    end

    def drop_deferred
      @deferred.pop
    end

    def apply_deferred
      @deferred.each do |deferred| deferred.call end
      @deferred.clear
    end
  end
end
