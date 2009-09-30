#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  module Safe
    @safe = {}

    def self.save(call, as)
      klass, meth = call.split('.')
      @safe[as]   = Object.const_get(klass).method(meth)
      module_eval(<<-END_OF_METHOD)
        def #{as}(*args, &block)
          ::BareTest::Safe.safe[#{as.inspect}].call(*args, &block)
        end
      END_OF_METHOD
    end

    class << self
      attr_reader :safe
    end

    {
      "Dir.glob"         => 'dir_glob',
      "File.exist"       => 'file_exist',
      "File.expand_path" => 'file_expand_path',
      "File.join"        => 'file_join',
      "File.read"        => 'file_read',
      "File.readlines"   => 'file_readlines',
      "Hash.new"         => 'hash_new',
      "IRB.conf"         => 'irb_conf',
      "IRB.setup"        => 'irb_setup',
      "Module.new"       => 'module_new',
      "StringIO.new"     => 'string_io_new',
      "Struct.new"       => 'struct_new',
      "Time.now"         => 'time_now',
    }.each do |call, as| save(call, as) end
  end
end
