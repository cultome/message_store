class MessageStore::RedisCache
  include MessageStore::RedisStore
  include MessageStore::Config

  def update(stream : String, entity : Entity)
    with_cache do |cache|
      cache.set(stream, {
        "data"     => entity,
        "metadata" => entity.metadata,
      }.to_json)
    end
  end

  def fetch(stream : String) : Tuple(String?, String?)
    with_cache do |cache|
      payload = cache.get(stream)

      if payload.nil?
        {nil, nil}
      else
        data = JSON.parse(payload)

        {data["data"].to_json, data["metadata"].to_json}
      end
    end
  end
end

module MessageStore::Cacheable
  def cache
    @cache ||= RedisCache.new
  end
end
