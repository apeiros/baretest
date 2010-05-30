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
    Inflect = {
      'Suite'   => Hash.new('Suites').update(1 => 'Suite'),
      'suite'   => Hash.new('suites').update(1 => 'suite'),
      'Unit'    => Hash.new('Units').update(1 => 'Unit'),
      'unit'    => Hash.new('units').update(1 => 'unit'),
      'Test'    => Hash.new('Tests').update(1 => 'Test'),
      'test'    => Hash.new('tests').update(1 => 'test'),
      'success' => Hash.new('successes').update(1 => 'success'),
      'pending' => Hash.new('pendings').update(1 => 'pending'),
      'skipped' => Hash.new('skipped'),
      'failure' => Hash.new('failures').update(1 => 'failure'),
      'error'   => Hash.new('errors').update(1 => 'error'),
    }

    @by_path = {}
    class <<self; attr_reader :by_path; end

    # Load a formatter
    def self.load(format)
      return format if format.is_a?(BareTest::Formatter) # FIXME, ducktype this
      require "baretest/formatter/#{format}"
      Formatter.by_path["baretest/formatter/#{format}"]
    end

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
      Formatter.by_path[path] = self
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

    def initialize(runner, options)
      @runner            = runner
      @options           = options
      @output_device     = options[:output] || $stdout
      @input_device      = options[:input] || nil
      @interactive       = @input_device && @input_device.tty? rescue false
      @auto_strip_colors = !@interactive
      @deferred          = []
      @indent_string     = '  '
    end

    def start_all; end
    def start_suite(suite); end
    def start_unit(unit); end
    def start_test(test); end
    def end_test(test, status, elapsed_time); end
    def end_unit(unit, status_collection, elapsed_time); end
    def end_suite(suite, status_collection, elapsed_time); end
    def end_all(status_collection, elapsed_time); end

    def puts(*args)
      @output_device.puts(*auto_strip_colors(*args))
    end

    def print(*args)
      @output_device.print(*auto_strip_colors(*args))
    end

    def printf(*args)
      @output_device.printf(*auto_strip_colors(*args))
    end

    def auto_strip_colors(*args)
      return args unless @auto_strip_colors
      args.map { |arg| arg.gsub(/\e\[[^m]*m/, '') }
    end

    def indent(item, offset=0)
      @indent_string*(item.nesting_level+offset)
    end

    def backtrace(status)
      return ['No backtrace'] unless backtrace = status.exception && status.exception.backtrace
      @options[:verbose] ? backtrace : backtrace.first(1)
    end

    # Add data to output, but mark it as deferred
    # We defer in order to be able to ignore suites. Ignored suites that
    # contain unignored suites/assertions must be displayed, ignored suites
    # that don't, will be popped from the deferred-stack
    def defer(deferred=true, &block)
      @deferred << (deferred ? block : proc{})
    end

    def drop_last_deferred
      @deferred.pop
    end

    def apply_deferred
      @deferred.each do |deferred| deferred.call end
      @deferred.clear
    end
  end
end
