#--
# Copyright 2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'command/kernel'
require 'command/nofileerror'
require 'command/nodirectoryerror'
require 'command/filenotfounderror'
require 'command/directorynotfounderror'
require 'command/types'
require 'command/argument'
require 'command/option'
require 'command/env'
require 'command/result'
require 'command/decoratinghash'
require 'command/definition'
require 'command/parser'



module Command
  def self.define(*args, &block)
    @main = Definition.new(*args, &block)
    @main
  end

  def self.with(argv, &block)
    parser = Parser.new($command, argv)
    parser.instance_eval(&block)
    parser
  end
end
