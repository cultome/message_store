require "db"
require "json"
require "pg"
require "redis"
require "uuid"
require "./message_store/event"
require "./message_store/redis_store"
require "./message_store/config"
require "./message_store/*"

module MessageStore
  VERSION = "0.1.0"

  class MessageStore
    include Config
    include Writer
    include StreamReader
    include Subscriber
    include Notifier
    include Cacheable
    include Snapshoter
    include EventFetcher
    include EntityFetcher
    include Utils
    include RedisStore
    include PostgresStore
    include Metrics
  end
end
