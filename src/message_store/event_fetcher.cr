module MessageStore::EventFetcher
  EVENT_FIELDS      = "id, stream_name, stream_category, stream_id, type, position, global_position, data, metadata, time"
  EVENT_FIELD_TYPES = {String, String, String?, String?, String, Int64, Int64, JSON::Any, JSON::Any, Time}

  def event_by_id(event_id : String, event_class : Event.class)
    with_db do |db|
      event_data = db.query_one("select #{EVENT_FIELDS} from #{config.messages_table} where id = $1", event_id, as: EVENT_FIELD_TYPES)
      map_event event_class, *event_data
    end
  end

  def events_from_position(position : Int64, stream : String, supported_events : Array(Event.class))
    events = [] of Event
    latest_position : Int64 = 0
    mapping = classname_table supported_events
    query = select_on_stream_query(EVENT_FIELDS, stream, "position > #{position}")

    with_db do |db|
      query_to_stream(db, query, stream) do |rs|
        event_instance = map_event mapping, *rs.read(*EVENT_FIELD_TYPES)

        events.push event_instance
      end
    end

    events
  end

  def map_event(
    mapping : Hash(String, Event.class),
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
    map_event(
      mapping[type],
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

  def map_event(
    event_class : Event.class,
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
    event_class.build(
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
