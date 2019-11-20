abstract class MessageStore::Event
  property metadata

  @metadata : Hash(String, String)? = {} of String => String

  abstract def to_json
end
