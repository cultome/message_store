module MessageStore::Metrics
  def meassure(description : String)
    start = Time.utc.nanoseconds
    yield
    lapse = Time.utc.nanoseconds - start

    puts "[*] #{description} took #{lapse}ns"
  end
end
