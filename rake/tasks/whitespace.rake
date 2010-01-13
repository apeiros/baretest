#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



desc "Shows all files with trailing whitespace and non-breaking spaces."
task :whitespace do
  suffixes = %w[.rb .rdoc .md .markdown .c .rake .txt]
  Dir.glob("**/*{#{suffixes.join(',')}}") do |path|
    data = File.read(path)
    if data =~ /\302\240|[ \t]+$/ then
      rdoc  = path =~ /.rdoc$/
      lines = data.split("\n")
      (1..(lines.length)).zip(lines) do |i,line|
        case line
          when /\302\240/
            puts "#{path}:#{i}:#{$`.size} - Nonbreaking space"
          when /^[ \t]+$/
            col   = $`.size
            match = $&
            size  = match.size
            if !rdoc || !(i > 1 && (lines[i-2][0,size] == match || lines[i-2][size-1,2] =~ /[ \t][^ \t]/)) then
              puts "#{path}:#{i}:#{col} - Empty line with whitespace"
            end
          when /[ \t]+$/
            puts "#{path}:#{i}:#{$`.size} - Trailing whitespace"
        end
      end
    end
  end
end
