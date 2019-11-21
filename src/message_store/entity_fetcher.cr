module MessageStore::EntityFetcher
  def fetch_entity(stream : String, entity_class : Entity.class)
    latest_version = stream_version stream
    cache_payload = cache.fetch(stream)

    entity = if cache_payload.nil? # not in cache
               fetch_from_snapshot(stream, entity_class)
             else
               entity_class.from_json cache_payload
             end

    if entity.version < latest_version
      old_entity_version = entity.version

      latest_events, last_version = events_from_position(entity.version, stream, entity_class)
      entity.update latest_events

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

    entity_class.new.update events
  end
end
