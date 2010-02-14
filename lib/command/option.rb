#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Command
  Option = Struct.new(:name, :short, :long, :negated, :necessity, :type, :declaration, :description) do
    def process!(argument)
      argument = Command::Types[type][argument] if type
      argument
    end
  end
end
