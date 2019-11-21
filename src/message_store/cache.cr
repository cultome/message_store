class MessageStore::RedisCache
  def update(stream : String, entity : Entity)
    puts "********** cache update entity *************"
  end

  def fetch(stream : String) : String?
    puts "********** cache fetch entity *************"
  end
end

module MessageStore::Cacheable
  def cache
    @cache ||= RedisCache.new
  end
end
