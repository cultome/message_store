require "db"
require "json"
require "logger"
require "pg"
require "redis"
require "uuid"
require "./message_store/event"
require "./message_store/handler"
require "./message_store/redis_store"
require "./message_store/config"
require "./message_store/utils/operation_success_event"
require "./message_store/utils/operation_failure_event"
require "./message_store/utils/operation_response_handler"
require "./message_store/utils/utils"
require "./message_store/*"

module MessageStore
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
