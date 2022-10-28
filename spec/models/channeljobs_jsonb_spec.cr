require "../spec_helper"

describe "Models::Kpbb::ChannelJob::JSONB" do
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

    log = Kpbb::ChannelJob.save!(data: sample1,
      run_at: Time.utc + 5.minutes,
      action: Kpbb::ChannelAction::Publish)
    log = Kpbb::ChannelJob.find!(log.id)

    # JSONB will "normalize" JSON,
    # so that the result will have it's keys in order
    sample1InOrder.should eq log.data
  end
end
