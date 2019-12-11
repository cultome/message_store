class MessageStore::Utils::OperationSuccessEvent < MessageStore::Event
  JSON.mapping(
    data: Hash(String, String)
  )
end
