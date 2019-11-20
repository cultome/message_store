module MessageStore::EntityFetcher
  def fetch_entity(stream : String, entity_class : Entity)
    latest_id = latest_position db, stream

    cache_payload = cache.fetch(stream)

    if cache_payload.nil? # not in cache
      snapshot_payload.fetch(stream)

      if snapshot_payload.nil? # not in snapshot
        with_db do |db|
          db.exec "select * from messages where "
        end
      end
    end
  end
end
