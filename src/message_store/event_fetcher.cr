module MessageStore::EventFetcher
  def events_from_position(position : Int64, stream : String, supported_events : Array(Event.class))
    events = [] of Event
    latest_position : Int64 = 0
    mapping = classname_table supported_events
    query = select_on_stream_query("id, stream_name, stream_category, stream_id, type, position, global_position, data, metadata, time", stream, "position > #{position}")

    with_db do |db|
      query_to_stream(db, query, stream) do |rs|
        id, stream_name, stream_category, stream_id, type, position, global_position, data, metadata, time = rs.read(String, String, String?, String?, String, Int64, Int64, JSON::Any, JSON::Any, Time)

        events.push mapping[type].build(
          id,
          stream_name,
          stream_category,
          stream_id,
          type,
          position,
          global_position,
          data,
          metadata,
          time
        )
      end
    end

    events
  end
end
