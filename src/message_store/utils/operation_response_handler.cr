class MessageStore::Utils::OperationResponseHandler < MessageStore::Handler
  @event : OperationSuccessEvent | OperationFailureEvent | Nil
  @success : Bool = false

  property event
  property success

  def handle(event : OperationSuccessEvent)
    @success = true
    @event = event
  end

  def handle(event : OperationFailureEvent)
    @success = false
    @event = event
  end
end
