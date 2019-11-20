module MessageStore::Notifier
  def notify(stream : String, notification : Notification)
    with_db { |db| db.exec("SELECT pg_notify($1, $2)", stream, notification.to_json) }
  end
end
