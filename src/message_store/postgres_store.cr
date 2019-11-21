module MessageStore::PostgresStore
  def with_db(&block : DB::Database ->)
    DB.open config.db_url do |db|
      yield db
    end
  end
end
