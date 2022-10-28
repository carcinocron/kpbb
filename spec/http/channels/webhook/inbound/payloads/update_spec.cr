require "../../../../../spec_helper"

describe "Http::Channels::Webhook::Inbound::Payload::Update" do
  it "rejects guest" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user.id)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    payload = Kpbb::Webhook::Inbound::Payload.save!(endpoint_id: endpoint.id, data: nil,
      cc_i16: Iom::CountryCode::UnitedStates, ip: "127.0.0.1",
      path: Kpbb::Webhook::Inbound::PayloadPath::Posts)
    req = HTTP::Request.new("POST", "#{channel.relative_url}/webhook/inbound/payloads/#{payload.id.to_b62}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_401
  end

  it "rejects user without membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user.id)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    payload = Kpbb::Webhook::Inbound::Payload.save!(endpoint_id: endpoint.id, data: nil,
      cc_i16: Iom::CountryCode::UnitedStates, ip: "127.0.0.1",
      path: Kpbb::Webhook::Inbound::PayloadPath::Posts)
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/payloads/#{payload.id.to_b62}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_404
  end

  it "rejects user with rank=0" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 0)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    payload = Kpbb::Webhook::Inbound::Payload.save!(endpoint_id: endpoint.id, data: nil,
      cc_i16: Iom::CountryCode::UnitedStates, ip: "127.0.0.1",
      path: Kpbb::Webhook::Inbound::PayloadPath::Posts)
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/payloads/#{payload.id.to_b62}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_404
  end

  it "accepts empty payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    payload = Kpbb::Webhook::Inbound::Payload.save!(endpoint_id: endpoint.id, data: nil,
      cc_i16: Iom::CountryCode::UnitedStates, ip: "127.0.0.1",
      path: Kpbb::Webhook::Inbound::PayloadPath::Posts)
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/payloads/#{payload.id.to_b62}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_ok
    res.status_code.should eq 200

    (payloads = Kpbb::Webhook::Inbound::Payload.all).size.should eq 1
    payloads[0].data_s.should be_nil
  end

  it "accepts reset_result=1" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    payload = Kpbb::Webhook::Inbound::Payload.save!(endpoint_id: endpoint.id, data: nil,
      cc_i16: Iom::CountryCode::UnitedStates, ip: "127.0.0.1",
      path: Kpbb::Webhook::Inbound::PayloadPath::Posts,
      result: ({:error => "yes"}).to_json)
    form = HTTP::Params.build do |form|
      form.add "reset_result", "1"
    end
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/payloads/#{payload.id.to_b62}", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    res.should be_json_200_ok
    res.status_code.should eq 200

    (payloads = Kpbb::Webhook::Inbound::Payload.all).size.should eq 1
    payloads[0].data_s.should be_nil
    payloads[0].result_s.should be_nil
  end
end
