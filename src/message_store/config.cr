module MessageStore
  class Configuration
    def db_url
      ENV.fetch("DB_URL")
    end

    def messages_table
      ENV.fetch("MESSAGES_TABLE")
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
