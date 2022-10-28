require "../../../../spec_helper"

describe "Cron::Feeds::Inbound::Fetches::FeedOrder" do
  it "attempts feeds in correct order" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel1 = Kpbb::Channel.factory(creator_id: user.id)
    channel2 = Kpbb::Channel.factory(creator_id: user.id)
    channel3 = Kpbb::Channel.factory(creator_id: user.id)
    endpoint1 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel1.id,
      lastpolled_at: nil,
      nextpoll_at: nil,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed1.xml")

    endpoint2 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel2.id,
      lastpolled_at: Time.utc - 2.hour,
      nextpoll_at: Time.utc - 2.hour,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed2.xml")

    endpoint3 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel3.id,
      lastpolled_at: Time.utc - 2.hour,
      nextpoll_at: Time.utc - 4.hour,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed3.xml")

    # same channel as endpoint3, but ignored to give other channels a chance
    endpoint4 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel3.id,
      lastpolled_at: Time.utc - 2.hour,
      nextpoll_at: Time.utc - 3.hour,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed4.xml")

    minute = Time.utc

    endpoints = Kpbb::Feed::Inbound::Endpoint.fetch_for_cron minute

    endpoints.size.should eq 3

    endpoints[0].id.should eq endpoint1.id # nil first
    endpoints[1].id.should eq endpoint3.id # 4.hour ago
    endpoints[2].id.should eq endpoint2.id # 2.hour ago
  end
end
