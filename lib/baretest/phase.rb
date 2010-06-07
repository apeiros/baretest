#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/status'



module BareTest
  class Phase

    attr_accessor :user_file
    attr_accessor :user_line

    def initialize(&code)
      @code      ||= code
      @user_file ||= nil
      @user_line ||= nil
      @user_code ||= nil
    end

    def phase
      raise "Your Phase subclass #{self.class.to_s} must override #phase."
    end

    def execute(test)
      raise Pending.new(phase, "No code provided") unless @code # no code? that means pending

      context = test.context
      context.__phase__ = phase
      context.instance_eval(&@code)
    end

    def user_code(until_line=nil)
      extract_code(@user_code, @user_file, @user_line, until_line)
    end

    def extract_code(proc_or_string, file, line, until_line=nil)
      use_parse_tree = nil
#       begin
#         require 'parse_tree'
#         require 'parse_tree_extensions'
#         require 'ruby2ruby'
#         use_parse_tree = true
#       rescue LoadError
#         use_parse_tree = false
#       end

      if proc_or_string.is_a?(String) then
        data
      elsif proc_or_string.is_a?(Proc) && use_parse_tree then
        decorate_user_code(data.to_ruby.sub(/\Aproc \{(?: \|[^|]*\|)?(.*)\}\z/m, '\1'))
      elsif file && line
        lines  = File.readlines(file)
        string = lines[(line-1)..(until_line || -1)].join("").sub(/[\r\n]*\z/, '').tr("\r", "\n")
        string.gsub!(/^\t+/) { |m| "  "*m.size }
        indent = string[/^ +/]
        string.gsub!(/^ {0,#{indent.size-1}}[^ ].*\z/m, '') # drop everything that is less indented
        string.gsub!(/^#{indent}/, '  ') # reindent
        string
      else
        "<<could not extract code>>"
      end
    end

    # Prepend the line number in front of ever line
    def insert_line_numbers(code, start_line=1) # :nodoc:
      digits       = Math.log10(start_line+code.count("\n")).floor+1
      current_line = start_line-1
      code.gsub(/^/) { sprintf '  %0*d  ', digits, current_line+=1 }
    end
  end
end



require 'baretest/phase/setup'
require 'baretest/phase/exercise'
require 'baretest/phase/verification'
require 'baretest/phase/teardown'
require 'baretest/phase/abortion'
