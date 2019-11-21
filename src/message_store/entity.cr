abstract class MessageStore::Entity
  property metadata

  @metadata = {} of String => String

  abstract def to_json

  def apply(event : Event)
    # noop
  end

  def version
    metadata.fetch("position", "0").to_i64
  end

  def update(events : Array(Event))
    events.each do |event|
      apply event
      @metadata = event.metadata
    end

    self
  end

  def self.projected_events : Array(Event)
    raise "Must implement #{self.name}.projected_events!"
  end
end
