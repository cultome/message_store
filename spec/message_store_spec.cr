require "./spec_helper"

describe MessageStore do
  context "#write" do
    it "simple write" do
      ms = MessageStore::MessageStore.new
      event = TestEvent.from_json({"name" => "value"}.to_json)

      ms.write(event, "spec/1")
    end

    it "with wrong expected version" do
      ms = MessageStore::MessageStore.new
      event = TestEvent.from_json({"name" => "value"}.to_json)

      expect_raises(Exception) { ms.write(event, "spec/1", -1) }
    end

    it "with expected version" do
      ms = MessageStore::MessageStore.new
      event = TestEvent.from_json({"name" => "value"}.to_json)

      current_version = ms.stream_version "spec/1"
      ms.write event, "spec/1", current_version
    end
  end

  context "#fetch_entity" do
    it "fetch from stream with id" do
      ms = MessageStore::MessageStore.new
      event = TestEvent.from_json({"name" => "entity"}.to_json)

      old_version = ms.stream_version "spec/4"
      ms.write event, "spec/4"

      entity = ms.fetch_entity("spec/4", TestEntity)

      entity.should_not be_nil
      if entity
        entity.name.should_not be_nil

        if entity.name
          entity.name.should eq "entity"
          entity.version.should eq (old_version + 1)
        end
      end
    end
  end

  it "#subscribe" do
    ms = MessageStore::MessageStore.new
    handler = TestHandler.new
    event = TestEvent.from_json({"name" => "value"}.to_json)

    ms.subscribe "spec:subscribe/1", handler, [TestEvent]
    ms.write(event, "spec:subscribe/1")
    sleep 0.1 # wait for message reception

    handler.response.should eq "value"
  end
end
