require "../spec_helper"

describe "Cron::Webhook::Inbound::ChannelPayload::Process" do
  it "webhook cron processes channel payloads" do
    minute = Time.utc.at_end_of_minute
    empty_db
    user = TestUser.new

    channel1 = Kpbb::Channel.factory(creator_id: user.id)
    channelmembership1 = Kpbb::ChannelMembership.save!(
      channel_id: channel1.id, user_id: user.id, rank: 1)
    endpoint1 = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id,
      channel_id: channel1.id)

    channel2 = Kpbb::Channel.factory(creator_id: user.id)
    channelmembership2 = Kpbb::ChannelMembership.save!(
      channel_id: channel2.id, user_id: user.id, rank: 1)
    endpoint2 = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id,
      channel_id: channel2.id)

    (payloads = Kpbb::Webhook::Inbound::Payload.all).size.should eq 0
    (payloads = Kpbb::Webhook::Inbound::Payload.fetch_one_per_endpoint(minute)).size.should eq 0

    body : Hash(String, String) = {"title" => "a cool title"}

    payload1 = Kpbb::Webhook::Inbound::Payload.save!(
      endpoint_id: endpoint1.id,
      data: Kpbb::Webhook::Inbound::Payload::Data.new(
        body: body,
        creator_id: user.id,
      ).to_json,
      cc_i16: Iom::CountryCode::UnitedStates, ip: "127.0.0.1",
      path: Kpbb::Webhook::Inbound::PayloadPath::Posts)

    # a second one, same channel, should not show up for cron
    payload2 = Kpbb::Webhook::Inbound::Payload.save!(
      endpoint_id: endpoint1.id,
      data: Kpbb::Webhook::Inbound::Payload::Data.new(
        body: body,
        creator_id: user.id,
      ).to_json,
      cc_i16: Iom::CountryCode::UnitedStates, ip: "127.0.0.1",
      path: Kpbb::Webhook::Inbound::PayloadPath::Posts)

    (payloads = Kpbb::Webhook::Inbound::Payload.all).size.should eq 2
    (payloads = Kpbb::Webhook::Inbound::Payload.fetch_one_per_endpoint(minute)).size.should eq 1

    # a payload with result NOT NULL should not show up for cron
    payload3 = Kpbb::Webhook::Inbound::Payload.save!(
      endpoint_id: endpoint2.id,
      data: Kpbb::Webhook::Inbound::Payload::Data.new(
        body: body,
        creator_id: user.id,
      ).to_json,
      result: ({:literally => "anything"}).to_json,
      cc_i16: Iom::CountryCode::UnitedStates, ip: "127.0.0.1",
      path: Kpbb::Webhook::Inbound::PayloadPath::Posts)

    (payloads = Kpbb::Webhook::Inbound::Payload.all).size.should eq 3
    (payloads = Kpbb::Webhook::Inbound::Payload.fetch_one_per_endpoint(minute)).size.should eq 1

    # a payload from a second channel should show up for cron
    payload4 = Kpbb::Webhook::Inbound::Payload.save!(
      endpoint_id: endpoint2.id,
      data: Kpbb::Webhook::Inbound::Payload::Data.new(
        body: body,
        creator_id: user.id,
      ).to_json,
      cc_i16: Iom::CountryCode::UnitedStates, ip: "127.0.0.1",
      path: Kpbb::Webhook::Inbound::PayloadPath::Posts)

    (payloads = Kpbb::Webhook::Inbound::Payload.all).size.should eq 4
    (payloads = Kpbb::Webhook::Inbound::Payload.fetch_one_per_endpoint(minute)).size.should eq 2

    (posts = Kpbb::Post.all).size.should eq 0
    Kpbb::Cron::Webhook::Inbound::Payload.run(minute: Time.utc + 1.minute)
    (posts = Kpbb::Post.all).size.should eq 2

    (payloads = Kpbb::Webhook::Inbound::Payload.all).size.should eq 4
    (payloads = Kpbb::Webhook::Inbound::Payload.fetch_one_per_endpoint(minute)).size.should eq 0

    # pretend the last payload was made further in the past
    Kpbb.db.exec <<-SQL
      UPDATE webhook_inbound_endpoints
      SET nextpost_at = NOW(),
        lastposted_at = NOW() - INTERVAL '10 minute'
    SQL

    (payloads = Kpbb::Webhook::Inbound::Payload.fetch_one_per_endpoint(minute)).size.should eq 1

    Kpbb::Cron::Webhook::Inbound::Payload.run(minute: Time.utc + 1.minute)
    (posts = Kpbb::Post.all).size.should eq 3
  end
end
