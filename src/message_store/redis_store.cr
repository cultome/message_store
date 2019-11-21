module MessageStore::RedisStore
  def with_cache(&block : Redis ->)
    Redis.open(url: config.redis_url) do |redis|
      yield redis
    end
  end
end
