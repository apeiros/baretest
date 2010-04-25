#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareTest

  class StatusCollection
    # The collection this statuscollection belongs to
    attr_reader :entity

    # The status identifier, see BareTest::Status. Symbol.
    attr_reader :count

    def initialize(entity)
      @entity = entity
      @count  = Hash.new(0)
    end

    def update(status_collection)
      @count[status_collection.entity] += 1
      @count.update(status_collection.count) do |key, my_value, other_value|
        my_value+other_value
      end
      self
    end

    def <<(status)
      @count[status.entity] += 1
      @count[status.code]   += 1
    end

    def values_at(*args)
      @count.values_at(*args)
    end

    def code
      BareTest::StatusOrder.find { |status| @count[status] > 0 } || :pending
    end

    def inspect # :nodoc:
      sprintf "#<%s:%p:%s count: %p>",
        self.class,
        @entity.class,
        @entity.description,
        @count
    end
  end
end
