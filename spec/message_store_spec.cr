require "./spec_helper"

describe MessageStore do
  it "#write" do
    ms = MessageStore::MessageStore.new
    event = TestEvent.new({"name" => "value"}, {"reply_to" => "spec:response"})

    ms.write(event, "spec/1")
  end

  it "#fetch_entity" do
  end

  it "#subscribe" do
    ms = MessageStore::MessageStore.new
    handler = TestHandler.new
    event = TestEvent.new({"name" => "value"}, {"reply_to" => "spec:response"})

    ms.subscribe "spec:subscribe/1", handler, [TestEvent]
    ms.write(event, "spec:subscribe/1")
    sleep 0.1 # wait for message reception

    handler.response.should eq "value"
  end
end
