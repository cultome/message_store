abstract class MessageStore::Handler
  abstract def handle(event : Event)
end
