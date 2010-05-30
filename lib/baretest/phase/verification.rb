#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase'



module BareTest
  class Phase
    class Verification < Phase
      attr_reader :description

      def initialize(description, options=nil, &code)
        if options then
          code = proc {
            raise BareTest::Phase::Pending.new(:verification, "Tagged as pending (#{options[:pending]})")
          } if options[:pending]
          code = proc {
            raise BareTest::Phase::Skip.new(:verification, "Tagged as skipped (#{options[:skip]})")
          } if options[:skip]
        end
        code ||= proc { pending("No code provided") }

        @description = description
        super() do
          value = instance_eval(&code)
          raise ::BareTest::Phase::Failure.new(:verification, "Verification failed (evaluated to #{value.inspect})") unless value
        end
      end

      def phase
        :verification
      end

      def inspect
        sprintf "#<%s %p>", self.class, @description
      end
    end
  end
end
