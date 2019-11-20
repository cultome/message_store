class MessageStore::RedisCache
  def update(stream : String, entity : Entity)
  end

  def fetch(stream : String) : String?
  end
end

module MessageStore::Cacheable
  def cache
    @cache ||= RedisCache.new
  end
end
