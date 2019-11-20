class MessageStore::Notification
  JSON.mapping(
    event_name: String,
    payload: String,
    metadata: String
  )

  def initialize(@event_name : String, @payload : String, @metadata : String)
  end

  def build_event(event_class : Event.class)
    payload = Hash(String, String).from_json(@payload)
    metadata = Hash(String, String).from_json(@metadata)

    event_class.new(payload, metadata)
  end
end
