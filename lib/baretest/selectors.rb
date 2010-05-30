#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  # Provides mechanics to filter units satisfying specific attributes.
  # The main type of selectors are:
  # * last-run-state - depends on the exit status in the most recent run of a verify
  # * tags - tags work via tags that have been added to a suite or exercise
  # * glob - a glob works via the file a verify is defined in
  module Selectors

    ArgvSelectorMatch = /\A(?:
      -%(.*)|   (?# negative state selector)
      -:(.*)|   (?# negative tag selector)
      \+?%(.*)| (?# positive state selector)
      \+?:(.*)| (?# positive tag selector)
      -(.*)|    (?# negative glob)
      \+?(.*)   (?# positive glob)
    )\z/x

    LastRunStatesHierarchy = {
      :run => {
        :success => {
          :aborted => {
            :aborted_manually => {
              :skipped => {
                :skipped_tag                => {},
                :skipped_component_missing  => {},
                :skipped_library_missing    => {},
                :skipped_dependency_missing => {},
              },
              :pending => {
                :pending_tagged   => {},
                :pending_setup    => {},
                :pending_exercise => {},
                :pending_verify   => {},
                :pending_teardown => {},
              },
            },
            :aborted_automatically => {
              :failure => {
                :failure_setup => {
                  :failure_component_missing  => {},
                  :failure_library_missing    => {},
                  :failure_dependency_missing => {},
                },
                :failure_verification => {},
              },
              :error => {
                :error_setup        => {},
                :error_exercise     => {},
                :error_verification => {},
                :error_teardown     => {},
              },
            },
          },
        },
        :unrun => {
          :new        => {},
          :deselected => {},
        },
      },
    }
    LastRunStateSets  = {}
    hierarchy_to_sets = proc do |state, subordinated_states, stack|
      LastRunStateSets[state] = [state]
      stack.each do |superordinated_state|
        LastRunStateSets[superordinated_state] << state
      end
      stack.push(state)
      subordinated_states.each do |key, value|
        hierarchy_to_sets[key, value, stack]
      end
      stack.pop
    end
    hierarchy_to_sets[:all, LastRunStatesHierarchy, []]



  module_function

    # Process an array of strings as they come from the command line and
    # convert them to a selectors array.
    def parse_argv_selectors(argv_selectors)
      globs  = []
      tags   = []
      states = []

      argv_selectors.each do |selector|
        raise "Invalid selector #{selector}" unless selector =~ ArgvSelectorMatch
        case
          when $1 then states << [:-, $1.to_sym]
          when $3 then states << [:+, $3.to_sym]
          when $2 then tags   << [:-, $2.to_sym]
          when $4 then tags   << [:+, $4.to_sym]
          when $5 then globs  << [:-, $5]
          when $6 then globs  << [:+, $6]
          else raise "Should never be reached"
        end
      end

      [globs, tags, states]
    end

    def units_by_tag(units)
      by_tag = Hash.new { |hash, key| hash[key] = [] }
      units.each do |unit|
        unit.tags.each do |tag|
          by_tag[tag] << test
        end
      end

      by_tag
    end

    def expand_globs(globs, default_glob=BareTest::DefaultGlobPattern)
      return Dir.glob(default_glob) if globs.empty?

      files = globs.first.first == :+ ? [] : Dir.glob(default_glob)
      globs.each do |op, glob|
        glob   = "#{glob}/**/*.rb" if File.directory?(glob)
        if op == :+ then
          files |= Dir.glob(glob)
        else
          files -= Dir.glob(glob)
        end
      end

      files
    end

    def select_by_last_run_state(units, last_run_state_selectors)
      state_set = last_run_state_selectors.first.first == :+ ? [] : LastRunStateSets.keys
      last_run_state_selectors.each do |op, state|
        raise "Invalid state: #{state}" unless LastRunStateSets.include?(state)
        if op == :+ then
          state_set |= LastRunStateSets[state]
        else
          state_set -= LastRunStateSets[state]
        end
      end

      units.select { |unit| state_set.include?(unit.last_run_state) }
    end

    def select_by_tags(units, units_by_tag, tag_selectors)
      units_set = tag_selectors.first.first == :+ ? [] : units
      tag_selectors.each do |op, tag|
        if op == :+ then
          units_set |= units_by_tag[tag]
        else
          units_set -= units_by_tag[tag]
        end
      end

      units_set
    end

  end
end
