require "spec"
require "../src/message_store"

class TestEvent < MessageStore::Event
  JSON.mapping(
    name: String
  )
end

class TestHandler < MessageStore::Handler
  property response

  def initialize(@response : String? = nil)
  end

  def handle(event : TestEvent)
    @response = event.name
  end
end

class TestEntity < MessageStore::Entity
  property name

  def initialize(@name : String? = nil)
  end

  def apply(event : TestEvent)
    @name = event.name
  end

  def self.projected_events
    [TestEvent]
  end
end
