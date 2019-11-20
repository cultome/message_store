module MessageStore::EntityFetcher
  def fetch_entity(stream : String, entity_class : Entity.class)
    latest_id = with_db { |db| latest_position db, stream }

    cache_payload = cache.fetch(stream)

    if cache_payload.nil? # not in cache
      snapshot_payload = snapshot.fetch(stream)

      if snapshot_payload.nil? # not in snapshot
        mapping = classname_table entity_class.projected_events
        query = select_on_stream_query("type, data, metadata", stream)
        events = [] of Event

        with_db do |db|
          query_to_stream(db, query, stream) do |rs|
            type, data, metadata = rs.read(String, JSON::Any, JSON::Any)

            events.push build_event(mapping[type], data, metadata)
          end
        end # with_db

        entity_class.project events
      end
    end
  end
end
