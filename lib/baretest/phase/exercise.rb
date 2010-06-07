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
        @user_file = nil
        @user_line = nil
        @user_code = code

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
          returned          = instance_eval(&code)
          @__returned__     = returned
          @__has_returned__ = true
          returned
        end
      end

      def decorated_user_code(code)
        code
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
