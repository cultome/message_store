class MessageStore::Utils::OperationFailureEvent < MessageStore::Event
  JSON.mapping(
    errors: Array(String)
  )

  def initialize(@errors : Array(String))
  end
end
