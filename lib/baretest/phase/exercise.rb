#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/phase'



module BareTest
  class Phase
    class Exercise < Phase
      attr_reader :description

      def initialize(description, options, &code)
        if options then
          code = proc {
            raise BareTest::Phase::Pending.new(:exercise, "Tagged as pending (#{options[:pending]})")
          } if options[:pending]
          code = proc {
            raise BareTest::Phase::Skip.new(:exercise, "Tagged as skipped (#{options[:skip]})")
          } if options[:skip]
        end
        code ||= proc { pending("No code provided") }

        @description = description
        super() do
          @__returned__ = instance_eval(&code)
        end
      end

      def phase
        :exercise
      end

      def inspect
        sprintf "#<%s %p>", self.class, @description
      end
    end
  end
end
