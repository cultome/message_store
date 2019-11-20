module MessageStore::EntityFetcher
  def fetch_entity(stream : String, entity_class : Entity.class)
    latest_id = with_db { |db| latest_position db, stream }

    cache_payload = cache.fetch(stream)

    if cache_payload.nil? # not in cache
      snapshot_payload = snapshot.fetch(stream)

      if snapshot_payload.nil? # not in snapshot
        mapping = entity_class.projected_events.each_with_object(Hash(String, Event.class).new) { |clazz, acc| acc[clazz.name] = clazz }

        events = [] of Event

        with_db do |db|
          query = select_on_stream_query("type, data, metadata", stream)
          rs = query_to_stream(db, query, stream)

          rs.each do
            type, data, metadata = rs.read(String, JSON::Any, JSON::Any)

            events.push build_event(mapping[type], data, metadata)
          end
        end # with_db

        entity_class.project events
      end
    end
  end
end
