# TODO implement metadata for tracking and relation
abstract class MessageStore::Event
  property metadata

  @metadata = {} of String => String

  abstract def to_json
end
