class MessageStore::RedisCache
  def fetch(stream : String) : String?
  end
end

module MessageStore::Cacheable
  def cache
    @cache ||= RedisCache.new
  end
end
