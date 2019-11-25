module MessageStore::Writer
  def write(event : Event, stream : String, expected_version : Int64? = nil)
    payload = event.to_json
    metadata = event.metadata.to_json
    event_name = event.class.name.split("::").last

    new_id = write_message event_name, payload, metadata, stream, expected_version

    write_message event_name, payload, metadata, event.reply_to if event.reply_to?

    if responds_to? :notify
      notification = Notification.new(event_name, new_id)
      notify(stream, notification)

      notify(event.reply_to, notification) if event.reply_to?
    end

    new_event = event.clone
    new_event.metadata["id"] = new_id
    new_event
  end

  private def write_message(event_type : String, payload : String, metadata : String, stream : String, expected_version : Int64? = nil) : String
    latest_version = stream_version stream
    unless expected_version.nil?
      raise "Invalid expected version! expected: #{expected_version}, actual: #{latest_version}" if expected_version != latest_version
    end

    name, category, stream_id = parse_stream stream
    id = UUID.random.to_s

    with_db do |db|
      db.exec(
        insert_message_stmt,
        id,
        name, category, stream_id,
        event_type,
        latest_version.nil? ? 1 : latest_version + 1,
        payload, metadata,
      )
    end

    id
  end

  private def insert_message_stmt
    <<-SQL
      INSERT INTO
        #{config.messages_table}
          (id, stream_name, stream_category, stream_id, type, position, data, metadata)
      VALUES
        ($1, $2, $3, $4, $5, $6, $7, $8);
    SQL
  end
end
