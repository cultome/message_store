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

    it "writes merged metadata" do
      ms = MessageStore::MessageStore.new
      event = TestEvent.from_json({"name" => "value"}.to_json).reply_to("reply/to")

      current_version = ms.stream_version "spec/1"
      new_event = ms.write event, "spec/1", current_version

      new_event = ms.event_by_id new_event.id, TestEvent
      new_event.reply_to.should eq "reply/to"
    end
  end

  context "#fetch_entity" do
    it "fetch from stream with id" do
      ms = MessageStore::MessageStore.new
      event = TestEvent.from_json({"name" => "entity"}.to_json)

      old_version = ms.stream_version "spec/4"
      ms.write event, "spec/4"

      entity = ms.fetch_entity "spec/4", TestEntity

      entity.should_not be_nil
      if entity
        entity.name.should_not be_nil

        if entity.name
          entity.name.should eq "entity"
          entity.version.should eq (old_version + 1)
        end
      end
    end

    it "create a snapshot after threshold writes" do
      ms = MessageStore::MessageStore.new
      event = TestEvent.from_json({"name" => "entity"}.to_json)

      before_snapshot = ms.snapshot.fetch "spec/8"

      ms.config.snapshot_threshold.times.each { ms.write event, "spec/8" }
      ms.fetch_entity "spec/8", TestEntity

      after_snapshot = ms.snapshot.fetch "spec/8"
      after_snapshot.should_not eq before_snapshot
    end

    it "does not create a snapshot below threshold" do
      ms = MessageStore::MessageStore.new
      event = TestEvent.from_json({"name" => "entity"}.to_json)

      before_snapshot = ms.snapshot.fetch "spec/8"

      (ms.config.snapshot_threshold - 2).times.each { ms.write event, "spec/8" }
      ms.fetch_entity "spec/8", TestEntity

      after_snapshot = ms.snapshot.fetch "spec/8"
      after_snapshot.should eq before_snapshot
    end

    it "restore from snapshot" do
      ms = MessageStore::MessageStore.new
    end
  end

  context "#subscribe" do
    it "subscribe and continue" do
      ms = MessageStore::MessageStore.new
      handler = TestHandler.new
      event = TestEvent.from_json({"name" => "value"}.to_json)

      ms.subscribe "spec:subscribe/1", handler, [TestEvent]
      ms.write(event, "spec:subscribe/1")
      sleep 0.1 # wait for message reception

      handler.response.should eq "value"
    end

    it "subscribe and wait" do
      ms = MessageStore::MessageStore.new
      handler = TestHandler.new
      event = TestEvent.from_json({"name" => "value_1"}.to_json)

      spawn ms.write(event, "spec:subscribe/2")

      ms.subscribe_and_wait "spec:subscribe/2", handler, [TestEvent]

      handler.response.should eq "value_1"
    end
  end

  context "Event" do
    it "add reply_to metadata" do
      event = TestEvent.from_json({"name" => "value"}.to_json)
      event.reply_to "spec/response"

      event.reply_to.should eq "spec/response"
      event.metadata["reply_to"].should eq "spec/response"
    end

    it "add follow metadata" do
      ms = MessageStore::MessageStore.new
      event_2 = TestEvent.from_json({"name" => "value"}.to_json)
      event_1 = ms.write TestEvent.from_json({"name" => "value"}.to_json), "spec/1"

      event_2.follow event_1

      event_2.follow.should eq event_1.id
      event_2.metadata["follow"].should eq event_1.id
    end

    it "add correlation_id metadata" do
      event = TestEvent.from_json({"name" => "value"}.to_json)
      event.correlation_id "123456"

      event.correlation_id.should eq "123456"
      event.metadata["correlation_id"].should eq "123456"
    end
  end
end
