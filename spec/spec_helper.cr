require "spec"
require "../src/message_store"

class TestEvent < MessageStore::Event
  def to_json
    @payload.to_json
  end
end

class TestHandler < MessageStore::Handler
  property response

  def initialize(@response : String? = nil)
  end

  def handle(event : TestEvent)
    @response = event.payload["name"]
  end
end
