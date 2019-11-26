module MessageStore::Subscriber
  def subscribe(stream : String, handler : Handler, events : Array(Event.class))
    create_listener(stream, handler, events){}
  end

  def subscribe_and_wait(stream : String, handler : Handler, events : Array(Event.class))
    close_ch = Channel(Nil).new

    close_fn = create_listener(stream, handler, events){ close_ch.send nil }

    close_ch.receive
    close_fn.call
  end

  private def create_listener(stream : String, handler : Handler, events : Array(Event.class), &block)
    mapping = classname_table events

    conn = PG.connect_listen(config.db_url, stream) do |update|
      meassure "Time to handle message to stream #{stream}" do
        notification = Notification.from_json update.payload

        if mapping.has_key? notification.event_name
          event_instance = event_by_id notification.id, mapping[notification.event_name]

          handler.handle event_instance

          block.call
        end
      end
    end

    ->(){ conn.close }
  end
end
