#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Kernel
private
  def Command(*args, &block)
    $command = Command.define(nil, *args, &block)
  end
end
