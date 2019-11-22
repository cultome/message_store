abstract class MessageStore::Entity < MessageStore::Event
  abstract def projected_events

  def apply(event : Event)
    # noop
  end

  def update(events : Array(Event))
    events.each do |event|
      apply event
      @metadata = event.metadata
    end

    self
  end
end
