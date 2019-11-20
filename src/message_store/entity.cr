abstract class MessageStore::Entity
  property version

  @version : Int64 = 0

  def apply(event : Event)
    #noop
  end

  def update(events : Array(Event))
    events.each do |event|
      apply event
    end

    self
  end

  def self.projected_events : Array(Event)
    raise "Must implement #{self.name}.projected_events!"
  end

  def self.project(events : Array(Event))
    self.new.update events
  end
end
