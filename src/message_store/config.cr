module MessageStore
  class Configuration
    def db_url
      ENV.fetch("DB_URL", "postgres://user:password@127.0.0.1:5432/db?retry_attempts=8&retry_delay=3")
    end

    def redis_url
      ENV.fetch("REDIS_URL", "redis://127.0.0.1")
    end

    def messages_table
      ENV.fetch("MESSAGES_TABLE", "messages")
    end

    def entity_snapshots_table
      ENV.fetch("ENTITY_SNAPSHOTS_TABLE", "entity_snapshots")
    end

    def snapshot_threshold
      ENV.fetch("SNAPSHOT_THRESHOLD", "5").to_i
    end
  end

  module Config
    def config
      @config ||= Configuration.new
    end
  end
end
