#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  class CodeBlock
    DefaultOptions = {
      :highlight          => nil,
      :line_numbers       => true,
      :template           => " \e[1m%0*d\e[0m   %s",
      :highlight_template => nil,
      :header             => "%s:%d",
      :footer             => nil,
    }

    def self.baretest(file, line, highlight=nil)
      read file,
           line,
           :highlight          => highlight,
           :header             => "  | Code of #{file}:#{line}\n  |\n",
           :template           => "  | \e[1m%0*d\e[0m   %s",
           :highlight_template => "  | \e[1m%0*d\e[0m   \e[43m%s\e[0m", # or 46?
           :footer             => ""
    end

    def self.read(file, from_line=1, opts={})
      unextracted(File.readlines(file), file, from_line, opts)
    end

    def self.unextracted(data, file, from_line=1, opts={})
      lines  = data.is_a?(String) ? data.lines : data.to_a
      string = lines[(from_line-1)..-1].join("").sub(/[\r\n]*\z/, '')
      string.gsub!(/^\t+/) { |m| "  "*m.size }
      indent = string[/^ +/]
      string.gsub!(/^ {0,#{indent.size-1}}[^ ].*\z/m, '') # drop everything that is less indented
      string.gsub!(/^#{indent}/, '') # unindent

      new(string, file, from_line, opts)
    end

    def initialize(code, file, starting_line=1, opts={})
      @code          = code
      @file          = file
      @starting_line = starting_line
      @options       = DefaultOptions.dup
      options!(opts)
    end

    def options!(value)
      @options.update(value)
      highlight            = @options[:highlight]
      @options[:highlight] = case highlight
        when nil then []
        when Integer then [highlight]
        when Array then highlight
        else highlight.to_a
      end
      @changed = true

      self
    end

    def to_s
      return @to_s unless @changed

      line_number        = @starting_line
      line_count         = @code.count("\n")
      normal_template    = @options[:template]
      highlight_template = @options[:highlight_template]
      highlight          = @options[:highlight]
      digits             = Math.log10(@starting_line+line_count).floor+1
      output             = []
      output            << @options[:header]
      @code.each_line do |line|
        template = highlight.include?(line_number) ? highlight_template : normal_template
        output  << sprintf(template, digits, line_number, line)
        line_number += 1
      end
      output << @options[:footer]
      @to_s = output.compact.join("")

      @to_s
    end

    def code(test, phase, highlight=nil)
      if phase_obj then
        puts 
        code = phase_obj.user_code
        line = phase_obj.user_line
        puts
      end
    end

    def insert_line_numbers(code, start_line=1, template='%0*d ')
      digits       = Math.log10(start_line+code.count("\n")).floor+1
      current_line = start_line-1
      code.gsub(/^/) { sprintf template, digits, current_line+=1 }
    end
  end
end
