class MessageStore::PostgresSnapshot
  def update(stream : String, entity : Entity)
    puts "********** update entity *************"
  end

  def fetch(stream : String) : String?
    puts "********** fetch entity *************"
  end
end

module MessageStore::Snapshoter
  def snapshot
    @snapshot ||= PostgresSnapshot.new
  end
end
