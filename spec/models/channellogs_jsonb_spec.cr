require "../spec_helper"

describe "Models::Kpbb::ChannelLog::JSONB" do
  it "saves JSONB" do
    empty_db

    sample1 = JSON.build do |json|
      json.object do
        json.field "b", "c"
        json.field "a", "b"
      end
    end
    sample1InOrder = JSON.build do |json|
      json.object do
        json.field "a", "b"
        json.field "b", "c"
      end
    end

    log = Kpbb::ChannelLog.save!(action: Kpbb::ChannelAction::Publish, data: sample1)
    log = Kpbb::ChannelLog.find!(log.id)

    # JSONB will "normalize" JSON,
    # so that the result will have it's keys in order
    sample1InOrder.should eq log.data
  end
end
