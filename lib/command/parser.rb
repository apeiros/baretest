#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Command
  class Parser
    attr_reader :definition
    attr_reader :command
    attr_reader :options
    attr_reader :argv

    def initialize(definition, argv)
      @definition = definition
      @argv       = argv
      @affix      = [] # arguments after '--'
      if i = argv.index('--')
        @affix     = argv[(i+1)..-1]
        @arguments = argv.first(i)
      else
        @arguments = @argv.dup
      end
      @affix      = []
      @options    = {}
    end

    def argument(name)
      position = @definition.argument_position[name]
      raise ArgumentError, "No argument #{name.inspect} available" unless position
      arguments[position]
    end

    def option(name)
      @options[name]
    end

    def arguments
      @arguments+@affix
    end

    def command!
      if @definition.commands_by_name.include?(@arguments.first)
        @command = @arguments.shift
      else
        @command = @definition.default_command
      end

      @command
    end

    def normalize_arguments!
      options    = @definition[@command].options_by_flag
      parse_argv = @arguments
      @arguments = []
      while arg = parse_argv.shift
        if arg =~ /\A-([^-]{2,})/ then
          flags  = $1
          until flags.empty?
            flag = flags.slice!(0,1)
            if opt  = options["-#{flag}"] then
              case opt.necessity
                when :required
                  @arguments << "-#{flag}"
                  @arguments << flags unless flags.empty?
                  flags = ""
                when :optional
                  raise "Invalid option - can't merge short options with optional arguments"
                when :none
                  @arguments << "-#{flag}"
                else
                  raise "Unknown necessity #{opt.necessity.inspect} for option #{opt}"
              end
            else
              @arguments << "-#{flag}#{flags}"
            end
          end
        else
          @arguments << arg
        end
      end
    end

    def options!(*flags)
      ignore_invalid_options = flags.delete(:ignore_invalid_options)
      options                = @definition[@command].options_by_flag # options available to this command
      env                    = @definition[@command].env_by_variable # options available to this command
      defaults               = @definition[@command].default_options # options available to this command

      normalize_arguments!

      parse_argv             = @arguments
      @arguments             = []

      defaults.each do |key, default|
        @options[key] = default unless @options.has_key?(key)
      end

      env.each do |key, definition|
        if ENV.has_key?(key) && !@options.has_key?(key) then
          mapped = options[definition.name]
          value  = mapped.process!(ENV[key])
          @options[key] = value
        end
      end

      while arg = parse_argv.shift
        if option = options[arg] then
          case option.necessity
            when :required
              value = option.process!(parse_argv.shift)
            when :optional
              if parse_argv.first && parse_argv.first !~ /\A-/ then
                value = option.process!(parse_argv.shift)
              else
                value = true
              end
            when :none
              value = true
          end
          @options[option.name] = (arg == option.negated) ? !value : value
        elsif arg =~ /\A-/ then
          raise "Invalid option #{arg}" unless ignore_invalid_options
          @arguments << arg
        else
          @arguments << arg
        end
      end

      @options
    end

    def result
      Result.new(@command, @options, @arguments+@affix)
    end

    def parse(*flags)
      command!
      options!(*flags)

      result
    end
  end
end
