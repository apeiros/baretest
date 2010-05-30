#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'baretest/formatter'
require 'baretest/persistence'
require 'baretest/status'
require 'baretest/statuscollection'
require 'baretest/test'



module BareTest

  # Run is the environment in which the suites and assertions are executed.
  # Prior to the execution, the Run instance extends itself with the
  # formatter that should be used and other runner related toolsets.
  # Your formatter can override:
  # :run_all::            Invoked once, before the first run_suite is ran. No
  #                       arguments.
  # :run_suite::          Invoked per suite. Takes the suite to run as argument.
  # :run_test_variants::  Invoked per assertion. Takes the assertion to execute
  #                       as argument.
  # :run_test::           Invoked per setup variation of each assertion. Takes
  #                       the assertion to execute and the setup blocks to use
  #                       as arguments.
  #
  # Don't forget to call super within your overrides, or the tests won't be
  # executed.
  class Run
    # The toplevel suite.
    attr_reader :suite

    # The initialisation blocks of extenders
    attr_reader :inits

    # Some statistics, standard count keys are:
    # :test::    the number of tests executed until now
    # :suite::   the number of suites executed until now
    # <status>:: the number of tests with that status (see
    #            BareTest::StatusOrder for a list of states)
    attr_reader :count

    attr_reader :global_status

    # Run the passed suite.
    # Calls run_all with the toplevel suite as argument and a block that
    # calls run_suite with the yielded argument (which should be the toplevel
    # suite).
    # Options accepted:
    # * :extenders:   An Array of Modules, will be used as argument to self.extend, useful e.g. for
    #   mock integration
    # * :format:      A string with the basename (without suffix) of the formatter to use - or a
    #   Module
    # * :interactive: true/false, will switch this Test::Run instance into IRB mode, where an error
    #   will cause an irb session to be started in the context of a clean copy of
    #   the assertion with all setup callbacks invoked
    #
    # The order of extensions is:
    # * :extender
    # * :format (extends with the formatter module)
    # * :interactive (extends with IRBMode)
    def initialize(suite, ignore, opts=nil)
      @suite              = suite
      @inits              = []
      @options            = opts || {}
      @options[:input]  ||= $stdin
      @options[:output] ||= $stdout
      @count              = @options[:count] || Hash.new(0)
      @ignore             = ignore
      @provided           = [] # Array's set operations are the fastest
      @skipped            = {}
      @last_run_states    = {}
      @persistence        = @options[:persistence]

      (BareTest.extender+Array(@options[:extender])).each do |extender|
        extend(extender)
      end

      # Extend with the output formatter
      formatter  = @options[:format] || 'none'
      @formatter = BareTest::Formatter.load(formatter).new(self, @options)

      # Extend with irb dropout code
      extend(BareTest::IRBMode) if @options[:interactive]

      # Initialize extenders
      @inits.each { |init| instance_eval(&init) }
    end

    # Hook initializers for extenders.
    # Blocks passed to init will be instance_eval'd at the end of initialize.
    # Example usage:
    #   module ExtenderForRun
    #     def self.extended(run_obj)
    #        run_obj.init do
    #          # do some initialization stuff for this module
    #        end
    #     end
    #   end
    def init(&block)
      @inits << block
    end

    def run
      start  = Time.now
      @formatter.start_all
      @global_status = run_suite(@suite)
      @formatter.end_all(@global_status, Time.now-start)
    end

    def run_suite(suite)
      start  = Time.now
      status = StatusCollection.new(suite)
      @formatter.start_suite(suite)
      suite.children.each do |child|
        case child
          when BareTest::Suite then status.update(run_suite(child))
          when BareTest::Unit  then status.update(run_unit(child))
          else raise TypeError, "Unknown type of child #{child.class} for #{suite}"
        end
      end
      @formatter.end_suite(suite, status, Time.now-start)
      status
    end

    def run_unit(unit)
      start  = Time.now
      status = StatusCollection.new(unit)
      @formatter.start_unit(unit)
      unit.each_test do |test, previous_verification_failed|
        status << run_test(test, previous_verification_failed)
      end
      @formatter.end_unit(unit, status, Time.now-start)
      status
    end

    def run_test(test, previous_verification_failed)
      start   = Time.now
      @formatter.start_test(test)

      if previous_verification_failed then
        test.status = Status.new(test, :skipped, :creation, "Previous verification failed")
      else
        test.setup
        test.exercise_and_verify
        test.teardown
      end

      # if nothing has yet set a status, then it's a success, hurray.
      test.status ||= Status.new(test, :success, :cleanup)

      @formatter.end_test(test, test.status, Time.now-start)

      test.status
    end
  end
end
