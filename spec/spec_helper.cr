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
