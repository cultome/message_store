class MessageStore::PostgresSnapshot
  def fetch(stream : String) : String?
  end
end

module MessageStore::Snapshoter
  def snapshot
    @snapshot ||= PostgresSnapshot.new
  end
end
