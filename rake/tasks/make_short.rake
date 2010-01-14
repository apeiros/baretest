desc "Create a one-file short version of baretest"
task :create_short do
  require 'pp'

  File.open("dev/generated-cleverly-short-test.rb", "w") { |fh|
    %w[
      lib/test.rb
      lib/test/assertion.rb
      lib/test/assertion/failure.rb
      lib/test/run.rb
      lib/test/suite.rb
    ].each { |path|
      code = File.read(path)

      # strip comments and whitespace lines and empty lines
      code.gsub!(/^[ \t]*\#.*\n|^[ \t]*\n/, '')

      # strip trailing newline
      code.chomp!

      # remove requires
      code.gsub!(/^require .*\n/, '')

      # compact multi-assigns
      code.gsub!(/(?:^[ \t]*@?\w+[ \t]*=[^>\n]+\n)+/) { |m|
        lhs, rhs = m.scan(/^[ \t]*(@?\w+)[ \t]*=[ \t]*([^\n]+)\n/).transpose
        m[/^[ \t]*/]+lhs.join(",")+" = "+rhs.join(",")+"\n"
      }

      # compact attr_readers
      code.gsub!(/(?:^[ \t]*attr_reader[ \t]*:[^\n]+\n)+/) { |m|
        m[/^[ \t]*/]+"attr_reader "+m.scan(/:\w+/).join(", ")+"\n"
      }

      fh.puts(code)
    }
  }
end
