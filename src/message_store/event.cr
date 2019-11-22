# TODO implement metadata for tracking and relation
abstract class MessageStore::Event
  property metadata

  @metadata = {} of String => String

  abstract def to_json

  def id
    @metadata["id"]
  end

  def follow=(event : Event)
    @metadata["follow"] = event.id
  end

  def follow
    @metadata["follow"]
  end

  def correlation_id=(value)
    @metadata["correlation_id"] = value
  end

  def correlation_id
    @metadata["correlation_id"]
  end

  def reply_to=(value)
    @metadata["reply_to"] = value
  end

  def reply_to
    @metadata["reply_to"]
  end

  def clone
    new_instance = self.class.from_json to_json
    new_instance.metadata = Hash(String, String).from_json metadata.to_json

    new_instance
  end
end
