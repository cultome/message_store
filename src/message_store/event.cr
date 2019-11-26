abstract class MessageStore::Event
  property metadata

  @metadata = {} of String => String

  abstract def to_json

  def id
    metadata["id"]
  end

  def version
    position
  end

  def position
    metadata.fetch("position", "0").to_i64
  end

  # esta muy feo
  def follow(event : Event)
    metadata["follow"] = event.id
    self
  end

  def follow
    metadata["follow"]
  end

  def follow?
    !metadata.fetch("follow", nil).nil?
  end

  # esta muy feo
  def correlation_id(value)
    metadata["correlation_id"] = value
    self
  end

  def correlation_id
    metadata["correlation_id"]
  end

  def correlation_id?
    !metadata.fetch("correlation_id", nil).nil?
  end

  # esta muy feo
  def reply_to(value)
    metadata["reply_to"] = value
    self
  end

  def reply_to
    metadata["reply_to"]
  end

  def reply_to?
    !metadata.fetch("reply_to", nil).nil?
  end

  def clone
    new_instance = self.class.from_json to_json
    new_instance.metadata = Hash(String, String).from_json metadata.to_json

    new_instance
  end

  def copy_to(event_class : Event.class)
    event_class.build self.to_json, metadata.to_json
  end

  def self.build(
    id : String,
    stream_name : String,
    stream_category : String?,
    stream_id : String?,
    type : String,
    position : Int64,
    global_position : Int64,
    data_payload : JSON::Any,
    metadata_payload : JSON::Any,
    time : Time
  ) : Event
    instance = self.from_json data_payload.to_json

    instance.metadata = {
      "type"            => self.name.split("::").last,
      "id"              => id,
      "stream_name"     => stream_name,
      "type"            => type,
      "position"        => position.to_s,
      "global_position" => global_position.to_s,
      "time"            => time.to_s,
    }

    instance.metadata["stream_category"] = stream_category unless stream_category.nil?
    instance.metadata["stream_id"] = stream_id unless stream_id.nil?

    unless metadata_payload.nil?
      payload_metadata = Hash(String, String).from_json(metadata_payload.to_json)
      instance.metadata.merge!(payload_metadata)
    end

    instance
  end

  def self.build(data_payload : Hash, metadata_payload : Hash? = nil) : Event
    event_instance = self.from_json data_payload.to_json

    unless metadata_payload.nil?
      event_instance.metadata = Hash(String, String).from_json(metadata_payload.to_json)
    end

    event_instance
  end

  def self.build(data_payload : String, metadata_payload : String? = nil) : Event
    event_instance = self.from_json data_payload

    unless metadata_payload.nil?
      event_instance.metadata = Hash(String, String).from_json(metadata_payload)
    end

    event_instance
  end
end
