class MessageStore::Notification
  JSON.mapping(
    event_name: String,
    payload: String,
    metadata: String
  )

  def initialize(@event_name : String, @payload : String, @metadata : String)
  end
end
