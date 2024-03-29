require "./spec_helper"

include MessageStore

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

      close_fn = ms.subscribe "spec:subscribe/1", handler, [TestEvent]
      ms.write(event, "spec:subscribe/1")
      sleep 0.1 # wait for message reception

      handler.response.should eq "value"

      close_fn.call
    end

    it "subscribe and wait" do
      ms = MessageStore::MessageStore.new
      handler = TestHandler.new
      event = TestEvent.from_json({"name" => "value_1"}.to_json)

      spawn ms.write(event, "spec:subscribe/2")

      ms.subscribe_and_wait_one "spec:subscribe/2", handler, [TestEvent]

      handler.response.should eq "value_1"
    end

    it "use the built in operation handler" do
      ms = MessageStore::MessageStore.new
      success_evt = Utils::OperationSuccessEvent.from_json({"data" => {"id" => "123456789"}}.to_json)
      fail_evt = Utils::OperationFailureEvent.from_json({"errors" => ["something went wrong!"]}.to_json)

      spawn ms.write(success_evt, "spec:subscribe/2")
      response = ms.subscribe_and_wait_operation "spec:subscribe/2"
      response.success.should be_true
      response.event.as(Utils::OperationSuccessEvent).data["id"].should eq "123456789"

      spawn ms.write(fail_evt, "spec:subscribe/2")
      response = ms.subscribe_and_wait_operation "spec:subscribe/2"
      response.success.should be_false
      response.event.as(Utils::OperationFailureEvent).errors.first.should eq "something went wrong!"
    end

    it "abort wait one timeout" do
      ms = MessageStore::MessageStore.new

      response = ms.subscribe_and_wait_operation "spec:subscribe/3", timeout_sec: 1
      response.success.should be_false
      response.event.as(Utils::OperationFailureEvent).errors.first == "operation timeout after 5 seconds"
    end

    it "use the built in custom operation handler" do
      ms = MessageStore::MessageStore.new
      handler = Utils::CustomOperationResponseHandler(Utils::OperationSuccessEvent, Utils::OperationFailureEvent).new
      success_evt = Utils::OperationSuccessEvent.from_json({"data" => {"id" => "123456789"}}.to_json)
      fail_evt = Utils::OperationFailureEvent.from_json({"errors" => ["something went wrong!"]}.to_json)

      spawn ms.write(success_evt, "spec:subscribe/2")
      ms.subscribe_and_wait_one "spec:subscribe/2", handler, [Utils::OperationSuccessEvent]
      handler.success.should be_true
      handler.event.should be_a(Utils::OperationSuccessEvent)

      spawn ms.write(fail_evt, "spec:subscribe/2")
      ms.subscribe_and_wait_one "spec:subscribe/2", handler, [Utils::OperationFailureEvent]
      handler.success.should be_false
      handler.event.should be_a(Utils::OperationFailureEvent)
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
