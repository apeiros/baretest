#--
# Copyright 2007-2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



namespace :notes do
  desc "Show all annotations"
  task :show, :tags do |t, args|
    tags = if args.tags then
      args.tags.split(/,\s*/)
    else
      Project.notes.tags
    end
    regex = /^.*(?:#{tags.map { |e| Regexp.escape(e) }.join('|')}).*$/
    count = 0
    found = 0
    puts "Searching for tags #{tags.join(', ')}"
    Project.notes.include.each { |glob|
      Dir.glob(glob) { |file|
        count += 1
        data   = File.read(file)
        header = false
        data.scan(regex) {
          found += 1
          unless header then
            puts "#{file}:"
            header = true
          end
          printf "- %4d: %s\n", $`.count("\n")+1, $&.strip
        }
      }
    }
    puts "Searched #{count} files and found nothing" if found.zero?
  end
end # namespace :notes

desc "Alias for notes:show. You have to use notes:show directly to use arguments."
task :notes => 'notes:show'
