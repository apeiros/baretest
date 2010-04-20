#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest
  module Phase
    class SetupRequire
      def initialize(path)
        @path = path
      end

      def description_variables
        {}
      end

      def length
        1
      end

      def setup(assertion, context)
        require @path
      rescue LoadError => e
        assertion.skip("Missing source file: #{@path} (#{e})")
      else
        true
      end

      def inspect
        sprintf "#<%s>", self.class
      end
    end
  end
end
