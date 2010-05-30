#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/context'



module BareTest
  class Unit
    attr_reader :suite
    attr_reader :exercise
    attr_reader :verifications
    attr_reader :length

    def initialize(suite, exercise)
      @suite         = suite
      @exercise      = exercise
      @verifications = []
      @length        = 0
    end

    # yields each combination of setup variant and verify as a BareTest::Test
    # instance.
    def each_test
      teardowns = @suite.ancestral_teardown
      exercise  = @exercise
      @verifications.each do |out_of_order_verifications| # those may be randomized. Optional randomization might be offered by a setting.
        out_of_order_verifications.each do |verification| # these must be executed in order and propagate failures.
          @suite.each_setup_variation do |setups|
            yield(Test.new(self, setups, exercise, verification, teardowns))
          end
        end
      end
    end

    # If count setups have been run, how many teardowns must be run?
    def teardown_count_for_setup_count(count)
      return @suite.ancestral_teardown.length unless count
      level = @suite.ancestral_setup_counts.find_index { |counts| count <= counts }
      if level > 0 then
        @suite.ancestral_teardown_counts[level-1]
      else
        0
      end
    end

    def finish_loading
      @length = 0
    end

    def nesting_level
      @suite.nesting_level+1
    end

    def out_of_order(verification)
      @verifications << [verification]
    end

    def in_order(verification)
      raise "Must have a 'verify' before any 'then_verify'" if @verifications.empty?
      @verifications.last << verification
    end
  end
end
