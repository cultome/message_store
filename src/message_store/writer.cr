module MessageStore::Writer
  def write(event : Event, stream : String)
    payload = event.to_json
    metadata = event.metadata.to_json
    event_name = event.class.name

    write_message event_name, payload, metadata, stream

    if responds_to? :notify
      notification = Notification.new(event_name, payload, metadata)
      notify(stream, notification)
    end
  end

  private def write_message(event_type : String, payload : String, metadata : String, stream : String) : String
    with_db do |db|
      stream_data = parse_stream stream
      latest_id = latest_position db, stream

      id = UUID.random.to_s
      db.exec(
        insert_message_stmt,
        id,
        stream_data[:name], stream_data[:category], stream_data[:id],
        event_type,
        latest_id.nil? ? 1 : latest_id + 1,
        payload, metadata,
      )

      id
    end
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
