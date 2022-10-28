require "../spec_helper"

describe "Models::Kpbb::ChannelJob::all_for_minute" do
  it "all_for_minute returns items in specific order 1" do
    empty_db
    action = Kpbb::ChannelAction::Publish

    logs = Array(Kpbb::ChannelJob).new
    logs << Kpbb::ChannelJob.save!(queued: true, run_at: Time.utc - 6.minutes, action: action)
    logs << Kpbb::ChannelJob.save!(queued: false, run_at: Time.utc - 5.minutes, action: action)
    logs << Kpbb::ChannelJob.save!(queued: true, run_at: Time.utc - 4.minutes, action: action)
    logs << Kpbb::ChannelJob.save!(queued: false, run_at: Time.utc - 3.minutes, action: action)
    logs << Kpbb::ChannelJob.save!(queued: true, run_at: Time.utc - 2.minutes, action: action)
    logs << Kpbb::ChannelJob.save!(queued: false, run_at: Time.utc - 1.minutes, action: action)

    list = Kpbb::ChannelJob.all_for_minute(minute: Time.utc)

    # queued=false should be first
    # because scheduled items will count as queued items
    # for the purpose of queue delays
    list.map(&.queued).should eq [false, false, false, true, true, true]
    # remaining sorts should be by run_at, then id
    list.map(&.id).should eq [
      logs[1].id, # id: 2  run_at: Time.utc - 5.minutes
      logs[3].id, # id: 4  run_at: Time.utc - 3.minutes
      logs[5].id, # id: 6  run_at: Time.utc - 1.minutes
      logs[0].id, # id: 1  run_at: Time.utc - 6.minutes
      logs[2].id, # id: 3  run_at: Time.utc - 4.minutes
      logs[4].id, # id: 5  run_at: Time.utc - 2.minutes
    ]
  end

  it "all_for_minute returns items in specific order 2" do
    empty_db
    action = Kpbb::ChannelAction::Publish

    logs = Array(Kpbb::ChannelJob).new
    logs << Kpbb::ChannelJob.save!(queued: true, run_at: Time.utc - 2.minutes, action: action)
    logs << Kpbb::ChannelJob.save!(queued: true, run_at: Time.utc - 1.minutes, action: action)
    logs << Kpbb::ChannelJob.save!(queued: true, run_at: Time.utc - 2.minutes, action: action)
    logs << Kpbb::ChannelJob.save!(queued: true, run_at: Time.utc - 1.minutes, action: action)
    logs << Kpbb::ChannelJob.save!(queued: true, run_at: Time.utc - 2.minutes, action: action)
    logs << Kpbb::ChannelJob.save!(queued: true, run_at: Time.utc - 1.minutes, action: action)

    list = Kpbb::ChannelJob.all_for_minute(minute: Time.utc)

    # pp list

    # sorts should be by run_at, then id
    list.map(&.id).should eq [
      logs[0].id, # id: 1  run_at: Time.utc - 2.minutes
      logs[2].id, # id: 3  run_at: Time.utc - 2.minutes
      logs[4].id, # id: 5  run_at: Time.utc - 2.minutes
      logs[1].id, # id: 2  run_at: Time.utc - 1.minutes
      logs[3].id, # id: 4  run_at: Time.utc - 1.minutes
      logs[5].id, # id: 6  run_at: Time.utc - 1.minutes
    ]
  end
end
