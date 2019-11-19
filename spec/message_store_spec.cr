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
  end
end
