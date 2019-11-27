module MessageStore::Subscriber
  def subscribe(stream : String, handler : Handler, events : Array(Event.class))
    create_listener(stream, handler, events) { |evt| }
  end

  def subscribe_and_wait_one(stream : String, handler : Handler, events : Array(Event.class))
    close_ch = Channel(Nil).new

    create_listener(stream, handler, events) { close_ch.send nil }

    close_ch.receive
  end

  def subscribe_and_wait_forever(stream : String, handler : Handler, events : Array(Event.class))
    close_ch = Channel(Nil).new

    create_listener(stream, handler, events) { |evt| }

    close_ch.receive
  end

  def subscribe_and_wait_signal(stream : String, handler : Handler, events : Array(Event.class), signal_ch : Channel)
    create_listener(stream, handler, events) { |evt| }

    signal_ch.receive
  end

  private def create_listener(stream : String, handler : Handler, events : Array(Event.class), &block : Event ->)
    mapping = classname_table events

    conn = PG.connect_listen(config.db_url, stream) do |update|
      meassure "Time to handle message in stream [#{stream}]" do
        notification = Notification.from_json update.payload

        if mapping.has_key? notification.event_name
          event_instance = event_by_id notification.id, mapping[notification.event_name]

          handler.handle event_instance

          block.call event_instance
        end
      end
    end

    ->{ conn.close }
  end
end
