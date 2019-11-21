module MessageStore::Reader
  def stream_version(stream : String)
    with_db { |db| latest_position db, stream }
  end
end
