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
