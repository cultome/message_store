abstract class MessageStore::Event
  property metadata
  property payload

  def initialize(@payload : Hash(String, String), @metadata : Hash(String, String))
  end

  abstract def to_json
end
