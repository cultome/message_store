class MessageStore::OperationResponse(S, F) < MessageStore::Handler
  @event : S | F | Nil
  @success : Bool = false

  property event
  property success

  def handle(event : S)
    @success = true
    @event = event
  end

  def handle(event : F)
    @success = false
    @event = event
  end
end
