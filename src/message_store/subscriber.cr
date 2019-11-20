module MessageStore::Subscriber
  def subscribe(stream : String, handler : Handler, events : Array(Event.class))
    spawn create_listener(stream, handler, events)
  end

  private def create_listener(stream : String, handler : Handler, events : Array(Event.class))
    mapping = events.each_with_object(Hash(String, Event.class).new) { |clazz, acc| acc[clazz.name] = clazz }

    PG.connect_listen(config.db_url, stream) do |update|
      notification = Notification.from_json update.payload

      if mapping.has_key? notification.event_name
        event_instance = mapping[notification.event_name].from_json notification.payload

        unless notification.metadata.empty?
          event_instance.metadata = Hash(String, String).from_json(notification.metadata)
        end

        handler.handle event_instance
      end
    end
  end

end
