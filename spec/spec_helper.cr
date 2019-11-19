require "spec"
require "../src/message_store"

class TestEvent < MessageStore::Event
  def to_json
    @payload.to_json
  end
end
