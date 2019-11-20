module MessageStore::EntityFetcher
  def fetch_entity(stream : String, entity_class : Entity.class)
    latest_version = with_db { |db| latest_position db, stream }
    cache_payload = cache.fetch(stream)

    entity = if cache_payload.nil? # not in cache
               fetch_from_snapshot(stream, entity_class)
             else
               entity_class.from_json cache_payload
             end

    if entity.version < latest_version
      old_entity_version = entity.version

      latest_events, last_version = events_from_position(entity.version, stream, entity_class)
      # TODO extract this idiom
      entity.update latest_events

      entity.version = last_version

      cache.update stream, entity

      if latest_version - old_entity_version >= config.snapshot_threshold
        snapshot.update stream, entity
      end
    end

    entity
  end

  private def fetch_from_snapshot(stream : String, entity_class : Entity.class)
    snapshot_payload = snapshot.fetch(stream)

    if snapshot_payload.nil? # not in snapshot
      calculate_projection(0, stream, entity_class)
    else
      entity_class.from_json snapshot_payload
    end
  end

  private def calculate_projection(from_position : Int64, stream : String, entity_class : Entity.class)
    project_from from_position, stream, entity_class
  end

  private def project_from(position : Int64, stream : String, entity_class : Entity.class)
    events, latest_position = events_from_position position, stream, entity_class

    entity = entity_class.project events
    entity.version = latest_position

    entity
  end

  private def events_from_position(position : Int64, stream : String, entity_class : Entity.class)
    mapping = classname_table entity_class.projected_events
    query = select_on_stream_query("position, type, data, metadata", stream, "position > #{position}")

    events = [] of Event
    latest_position : Int64 = 0

    with_db do |db|
      query_to_stream(db, query, stream) do |rs|
        position, type, data, metadata = rs.read(Int64, String, JSON::Any, JSON::Any)

        events.push build_event(mapping[type], data, metadata)
        latest_position = position
      end
    end

    {events, latest_position}
  end
end
