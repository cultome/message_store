class MessageStore::Utils::OperationFailureEvent < MessageStore::Event
  JSON.mapping(
    errors: Array(String)
  )
end
