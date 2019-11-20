require "db"
require "json"
require "pg"
require "uuid"
require "./message_store/*"

module MessageStore
  VERSION = "0.1.0"

  class MessageStore
    include Config
    include Writer
    include Subscriber
    include Notifier
    include Cacheable
    include Snapshoter
    include EntityFetcher
    include Utils
    include PostgresStore
  end
end
