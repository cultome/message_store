abstract class MessageStore::Event
  property payload
  property metadata

  def initialize(@payload : Hash(String, String), @metadata : Hash(String, String))
  end

  abstract def to_json
end
