#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Command
  class Definition
    RequiredOptionArgument = /[A-Z][A-Z_]*/
    OptionArgument         = /\[#{RequiredOptionArgument}\]|#{RequiredOptionArgument}/
    ShortOption            = /\A-[A-Za-z](?: #{OptionArgument})?\z/
    NegationSequence       = /\[(?:no-|with-|without-)\]/
    LongOption             = /\A--[A-Za-z0-9][A-Za-z0-9_-]*(?: #{OptionArgument})?\z/

    def self.create_argument(*args)
      name        = Symbol === args.first && args.shift
      usage       = args.shift
      bare        = usage[/\w+/]
      type        = Symbol === args.first && args.shift
      description = args.shift

      Argument.new(name, bare, usage, type, description)
    end

    # valid arguments:
    #   name # --> copy from parent
    #   name, short[, long][, type][, description]
    #   name, long[, type][, description]
    #
    # short can be
    # * '-?' (short option without argument)
    # * '-? REQUIRED' (short option with required argument)
    # * '-? [OPTIONAL]' (short option with optional
    # where ? is any of A-Za-z
    # examples:
    # * '-a'
    # * '-a [OPTIONAL_ARG]'
    # * '-a REQUIRED_ARG'
    #
    # long can be
    # * '--?' (short option without argument)
    # * '--? REQUIRED' (short option with required argument)
    # * '--? [OPTIONAL]' (short option with optional
    # where ? is [A-Za-z0-9][A-Za-z0-9-_]*
    # It may contain a negation sequence, which is one of '[no-]', '[with-]', '[without-]'
    # examples:
    # * '--colored'
    # * '--[no-]colors'
    # * '--port PORT'
    # * '--foo [OPTIONAL_ARG]'
    #
    # Only one of short and long may have the argument declared.
    # Usually you'll have the argument in long and only have it in short if
    # there's no long at all.
    #
    # type can be
    # * :Virtual
    # * :Boolean
    # * :String (default)
    # * :Integer
    # * :Float
    # * :Octal
    # * :Hex
    # * :File - requires the provided path to exist and be a file
    # * :Directory - requires the provided path to exist and be a directory
    # * :Path
    #
    # Exceptions (incomplete):
    # * ArgumentError with single argument if it doesn't identify an inheritable option
    # * ArgumentError on invalid short definition
    # * ArgumentError on invalid long definition
    # * ArgumentError on option argument declaration in both, short and long definition
    # * ArgumentError on invalid/unsupported type
    def self.create_option(name, *args)
      case args.first when nil, /\A-[^- ]/ then
        short = args.shift
      end
      case args.first when nil, /\A--[^- ]/ then
        long = args.shift
      end
      case args.first when nil, Symbol then
        type = args.shift
      end
      declaration = short ? [short,long].compact.join(", ") : "    #{long}"
      description = args.shift

      raise ArgumentError, "Too many arguments" unless args.empty?
      raise ArgumentError, "Invalid short declaration: #{short.inspect}" unless (short.nil? || short =~ ShortOption)
      raise ArgumentError, "Invalid long declaration: #{long.inspect}" unless (long.nil? || long =~ LongOption)
      raise ArgumentError, "Argument declaration must only be in one of short and long" if (short && long && short =~ /\s/ && long =~ /\s/)

      necessity        = :none
      extract_argument = nil
      extract_argument = short if short =~ /\s/
      extract_argument = long if long =~ /\s/
      if extract_argument then
        flag, *argument = extract_argument.split(/ /)
        extract_argument.replace(flag) # long/short should only contain the flag, not the argument declaration as well
        raise ArgumentError, "Multiple arguments for an option not yet supported" if argument.size > 1
        if argument.empty?
          necessity = :none
        elsif argument.first =~ /\A\[.*\]\z/ then
          necessity = :optional
        else
          necessity = :required
        end
      end

      negated = nil
      if long =~ NegationSequence then
        negated = long.delete('[]')
        long    = long.gsub(NegationSequence, '')
      end

      Option.new(name, short, long, negated, necessity, type, declaration, description)
    end


    attr_reader :arguments
    attr_reader :arguments_by_name
    attr_reader :default_options
    attr_reader :options_by_name
    attr_reader :options_by_flag
    attr_reader :commands_by_name
    attr_reader :default_command
    attr_reader :argument_position
    attr_reader :env_by_variable
    attr_reader :parent # parent= must update the DecoratingHashes

    def initialize(parent=nil, default_command=nil, default_options={}, &block)
      @default_command   = default_command
      @default_options   = DecoratingHash.new(@parent && @parent.default_options).update(default_options)
      @elements          = []
      @parent            = parent
      @arguments_by_name = DecoratingHash.new(@parent && @parent.arguments_by_name)
      @options_by_name   = DecoratingHash.new(@parent && @parent.options_by_name)
      @options_by_flag   = DecoratingHash.new(@parent && @parent.options_by_flag)
      @commands_by_name  = DecoratingHash.new(@parent && @parent.commands_by_name)
      @env_by_variable   = DecoratingHash.new(@parent && @parent.env_by_variable)
      @argument_position = {}
      @text              = []
      instance_eval(&block) if block
    end

    def [](command)
      command ? @commands_by_name[command] : self
    end

    def usage_text
      longest_arg_bare = @elements.grep(Argument).max { |a,b|
        a.bare.size <=> b.bare.size
      }
      longest_option = @elements.grep(Option).max { |a,b|
        a.declaration.size <=> b.declaration.size
      }
      longest_env_name = @elements.grep(Env).max { |a,b|
        a.variable.size <=> b.variable.size
      }
      longest_arg_bare = longest_arg_bare && longest_arg_bare.bare.size
      longest_option   = longest_option && longest_option.declaration.size
      longest_env_name = longest_env_name && longest_env_name.variable.size
      arguments = @elements.grep(Argument)

      @elements.map { |e|
        case e
          when :usage
            "Usage: #{File.basename($0)} #{arguments.map{|a|a.usage}.join(' ')}\n"
          when Symbol
            "  #{e.inspect}\n"
          when Option
            sprintf "  %*s%s\n",
                    -(longest_option+2),
                    e.declaration,
                    e.description
          when Env
            sprintf "* %*s%s\n",
                    -longest_env_name-2,
                    e.variable,
                    @options_by_name[e.name].description
          when String
            e+"\n"
          when Argument
            indent = "\n     "+(" "*longest_arg_bare)
            sprintf "  %*s%s\n",
                    -(longest_arg_bare+3),
                    "#{e.bare}:",
                    e.description.to_s.gsub(/\n/, indent)
          when Definition
          else
            "unimplemented(#{e.class})"
        end
      }.join('')
    end

    def usage
      @elements << :usage
    end

    def argument(*args)
      unless @argument_position[args.first]
        @argument_position[args.first] = @argument_position.size
      end

      if args.size == 1 then
        argument   = @arguments_by_name[args.first]
        raise ArgumentError, "No argument with name #{args.first.inspect} in any parent found." unless argument
      else
        argument    = self.class.create_argument(*args)
        @arguments_by_name[argument.name] = argument
      end
      @elements << argument

      argument
    end

    def virtual_argument(*args)
      if args.size == 1 then
        argument   = @arguments_by_name[args.first]
        raise ArgumentError, "No argument with name #{args.first.inspect} in any parent found." unless argument
      else
        argument    = self.class.create_argument(*args)
        @arguments_by_name[argument.name] = argument
      end

      @elements << argument
      argument
    end

    def option(*args)
      if args.size == 1 then
        inherited_option = @options_by_name[args.first]
        raise ArgumentError, "No inherited option #{args.first.inspect}" unless inherited_option
        @elements << inherited_option

        inherited_option
      else
        option = self.class.create_option(*args)

        @options_by_name[option.name]    = option
        @options_by_flag[option.short]   = option
        @options_by_flag[option.long]    = option
        @options_by_flag[option.negated] = option
        @elements << option

        option
      end
    end
    alias o option

    def text(*args)
      if args.size == 2 then
        indent, text = *args
        text = text.gsub(/^/, indent)
      else
        text = args.first
      end
      @text     << text
      @elements << text
    end

    def placeholder(identifier)
      @elements << identifier
    end

    def env_option(name, variable)
      env = Env.new(name, variable)
      @env_by_variable[variable] = env
      @elements << env
    end

    def command(*args, &block)
      definition = Definition.new(self, *args, &block)
      @commands_by_name[args.first] = definition
      @elements << definition
    end
  end
end
