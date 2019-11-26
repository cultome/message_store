module MessageStore::Metrics
  def meassure(description : String)
    start = Time.utc.millisecond
    yield
    lapse = Time.utc.millisecond - start

    puts "[*] #{description} took #{lapse}ms"

    lapse
  end
end
