class MessageStore::PostgresSnapshot
  def update(stream : String, entity : Entity)
  end

  def fetch(stream : String) : String?
  end
end

module MessageStore::Snapshoter
  def snapshot
    @snapshot ||= PostgresSnapshot.new
  end
end
