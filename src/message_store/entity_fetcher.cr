module MessageStore::EntityFetcher
  def fetch_entity(stream : String, entity_class : Entity.class)
    latest_version = stream_version stream
    entity = fetch_from_cache stream, entity_class

    if entity.version < latest_version
      old_entity_version = entity.version

      entity = calculate_projection(0, stream, entity_class)
      cache.update stream, entity

      if latest_version - old_entity_version >= config.snapshot_threshold
        snapshot.update stream, entity
      end
    end

    entity
  end

  private def fetch_from_cache(stream : String, entity_class : Entity.class)
    data, meta = cache.fetch(stream)

    if data.nil? # not in cache
      fetch_from_snapshot(stream, entity_class)
    else
      entity = entity_class.from_json data
      unless meta.nil?
        entity.metadata = Hash(String, String).from_json meta
      end

      entity
    end
  end

  private def fetch_from_snapshot(stream : String, entity_class : Entity.class)
    data, meta = snapshot.fetch(stream)

    if data.nil? # not in snapshot
      snapshot.init(stream, entity_class)

      entity_class.new
    else
      entity = entity_class.from_json data
      unless meta.nil?
        entity.metadata = Hash(String, String).from_json meta
      end

      entity
    end
  end

  private def calculate_projection(from_position : Int64, stream : String, entity_class : Event.class)
    instance = entity_class.new

    events = events_from_position from_position, stream, instance.projected_events

    instance.update events
  end
end
