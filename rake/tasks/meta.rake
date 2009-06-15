#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



namespace :meta do
  task :prerequisite do
    Project.manifest.__finalize__
  end

  task :show do
    render = proc do |name, show, depth|
      show = show.__hash__ if SilverPlatter::Project::Description === show
      if Hash === show then
        puts "#{'  '*depth}#{name}:"
        show.each do |k,v|
          render[k, v, depth+1]
        end
      else
        puts "#{'  '*depth}#{name}: #{show.inspect}"
      end
    end

    render['Project', Project.__hash__, 0]
  end
end  # namespace :meta

#desc 'Alias to manifest:check'
#task :manifest => 'manifest:check'
