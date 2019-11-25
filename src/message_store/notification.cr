class MessageStore::Notification
  JSON.mapping(
    event_name: String,
    id: String,
  )

  def initialize(@event_name : String, @id : String)
  end
end
