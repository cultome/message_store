module MessageStore::Subscriber
  def subscribe(stream : String, handler : Handler, events : Array(Event.class))
    spawn create_listener(stream, handler, events)
  end

  private def create_listener(stream : String, handler : Handler, events : Array(Event.class))
    mapping = classname_table events

    PG.connect_listen(config.db_url, stream) do |update|
      meassure "Time to handle message to stream #{stream}" do
        notification = Notification.from_json update.payload

        if mapping.has_key? notification.event_name
          event_instance = event_by_id notification.id, mapping[notification.event_name]

          handler.handle event_instance
        end
      end
    end
  end
end
