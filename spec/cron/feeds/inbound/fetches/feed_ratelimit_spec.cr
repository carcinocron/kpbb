require "../../../../spec_helper"

# note: minimum time between polls is 1 hour
describe "Cron::Feeds::Inbound::Fetches::FeedOrder" do
  it "sets frequency value during inbound endpoint fetch run" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel1 = Kpbb::Channel.factory(creator_id: user.id)
    endpoint1 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel1.id,
      lastpolled_at: nil,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed1.xml")

    minute = Time.utc
    endpoints = Kpbb::Feed::Inbound::Endpoint.fetch_for_cron minute

    endpoints.size.should eq 1
    endpoints[0].frequency.should eq 0

    Kpbb::Cron::Feed::Inbound::Endpoint::Fetch.run minute

    endpoints = Kpbb::Feed::Inbound::Endpoint.all
    endpoints.size.should eq 1
    endpoints[0].frequency.should eq 10
    (endpoints[0].nextpoll_at.not_nil! - endpoints[0].lastpolled_at.not_nil!).total_minutes.floor.should eq 60
  end

  it "frequency math results in a value between 1 hour and 18 hours" do
    # 10/hr = 21,600
    # 1/hr = 2,160
    # 0.5/hr = 1,080
    # 0.25/hr = 540
    # 0.125/hr = 270
    # 2/day = 180
    # 1/day = 90
    # 0.5/day = 45
    # 1/week = 12
    # 1/month = 3

    list : Array(NamedTuple(x: Float32, y: Float32)) = [
      # x: freq over 90 days
      # y: 1..12 hours delay for nextpoll_at
      {x: 2160_f32, y: 1.0_f32},
      {x: 1080_f32, y: 1.0_f32},
      {x: 540_f32, y: 1.0_f32},
      {x: 271_f32, y: 1.0_f32},
      {x: 270_f32, y: 1.0_f32},
      {x: 269_f32, y: 1.0111262_f32},
      {x: 180_f32, y: 2.1567755_f32},
      {x: 90_f32, y: 3.8819716_f32},
      {x: 45_f32, y: 5.3326826_f32},
      {x: 12_f32, y: 7.490202_f32},
      {x: 3_f32, y: 9.103986_f32},
      {x: 2_f32, y: 9.479553_f32},
      {x: 1_f32, y: 12.0_f32},
      {x: 0.1_f32, y: 12_f32},
      {x: 0.01_f32, y: 12_f32},
      {x: 0_f32, y: 12.0_f32},
      {x: -1_f32, y: 12.0_f32},
    ]

    list.each do |v|
      # pp ({:x => v[:x], :y => Kpbb::Cron::Feed::Inbound::Endpoint::Fetch.freq_to_nextpoll_hr(v[:x])})
      Kpbb::Cron::Feed::Inbound::Endpoint::Fetch.freq_to_nextpoll_hr(v[:x]).should eq (v[:y])
    end
  end

  it "sets nextpoll_at for endpoint with frequency=5" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel1 = Kpbb::Channel.factory(creator_id: user.id)
    endpoint1 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel1.id,
      frequency: 5, # only 5 entries in last 90 days
      created_at: Time.utc - 2.years,
      lastpolled_at: Time.utc - 61.minute,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed1.xml")

    minute = Time.utc
    endpoints = Kpbb::Feed::Inbound::Endpoint.fetch_for_cron minute

    endpoints.size.should eq 1
    endpoints[0].frequency.should eq 5

    Kpbb::Cron::Feed::Inbound::Endpoint::Fetch.run minute

    endpoints = Kpbb::Feed::Inbound::Endpoint.all
    endpoints.size.should eq 1
    # endpoints[0].frequency.should eq 10
    (endpoints[0].nextpoll_at.not_nil! - endpoints[0].lastpolled_at.not_nil!).total_minutes.floor.should eq 514.0
  end

  it "sets nextpoll_at for endpoint with frequency=180" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel1 = Kpbb::Channel.factory(creator_id: user.id)
    endpoint1 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel1.id,
      frequency: 180, # only 180 entries in last 90 days
      created_at: Time.utc - 2.years,
      lastpolled_at: Time.utc - 61.minute,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed1.xml")

    minute = Time.utc
    endpoints = Kpbb::Feed::Inbound::Endpoint.fetch_for_cron minute

    endpoints.size.should eq 1
    endpoints[0].frequency.should eq 180

    Kpbb::Cron::Feed::Inbound::Endpoint::Fetch.run minute

    endpoints = Kpbb::Feed::Inbound::Endpoint.all
    endpoints.size.should eq 1
    # endpoints[0].frequency.should eq 10
    (endpoints[0].nextpoll_at.not_nil! - endpoints[0].lastpolled_at.not_nil!).total_minutes.floor.should eq 129.0
  end

  it "skips feeds polled recently" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel1 = Kpbb::Channel.factory(creator_id: user.id)
    channel2 = Kpbb::Channel.factory(creator_id: user.id)
    endpoint1 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel1.id,
      lastpolled_at: nil,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed1.xml")

    endpoint2 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel2.id,
      lastpolled_at: Time.utc - 59.minute,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed2.xml")

    minute = Time.utc
    endpoints = Kpbb::Feed::Inbound::Endpoint.fetch_for_cron minute

    endpoints.size.should eq 1
    endpoints[0].nextpoll_at.should be_nil
  end

  it "skips slow feeds" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel1 = Kpbb::Channel.factory(creator_id: user.id)
    channel2 = Kpbb::Channel.factory(creator_id: user.id)
    endpoint1 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel1.id,
      lastpolled_at: Time.utc - 2.hour,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed1.xml")

    minute = Time.utc
    endpoints = Kpbb::Feed::Inbound::Endpoint.fetch_for_cron minute

    endpoints.size.should eq 1
    endpoints[0].nextpoll_at.should be_nil
  end
end
