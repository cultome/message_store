abstract class MessageStore::Entity
  def apply(event : Event)
    #noop
  end

  def self.projected_events : Array(Event)
    raise "Must implement #{self.name}.projected_events!"
  end

  def self.project(events : Array(Event))
    instance = self.new

    events.each_with_object(instance) do |event, entity|
      entity.apply event
    end
  end
end
