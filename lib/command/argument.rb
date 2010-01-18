#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Command
  Argument = Struct.new(:name, :bare, :usage, :type, :description)
end
