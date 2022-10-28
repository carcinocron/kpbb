require "../../../../../spec_helper"

describe "Http::Channels::Feed::Inbound::Payloads::List" do
  it "rejects guest" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user.id)
    endpoint = Kpbb::Feed::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    payload = Kpbb::Feed::Inbound::Payload.save!(endpoint_id: endpoint.id, data: nil,
      guid: "https://www.example.com/blogs/entry1.html",
      path: Kpbb::Feed::Inbound::PayloadPath::Posts)
    req = HTTP::Request.new("GET", "#{channel.relative_url}/feed/inbound/payloads", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login

    req = HTTP::Request.new("GET", "#{channel.relative_url}/feed/inbound/payloads", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_401
  end

  it "rejects random user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user1.id)
    endpoint = Kpbb::Feed::Inbound::Endpoint.factory(creator_id: user1.id, channel_id: channel.id)
    payload = Kpbb::Feed::Inbound::Payload.save!(endpoint_id: endpoint.id, data: nil,
      guid: "https://www.example.com/blogs/entry1.html",
      path: Kpbb::Feed::Inbound::PayloadPath::Posts)

    user2 = TestUser.new(handle: "username2")
    req = user2.request("GET", "#{channel.relative_url}/feed/inbound/payloads", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html

    req = user2.request("GET", "#{channel.relative_url}/feed/inbound/payloads", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403
  end

  it "rejects unranked user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user1.id)
    channelmembership1 = Kpbb::ChannelMembership.save!(user_id: user1.id, channel_id: channel.id, rank: 0)
    endpoint = Kpbb::Feed::Inbound::Endpoint.factory(creator_id: user1.id, channel_id: channel.id)
    payload = Kpbb::Feed::Inbound::Payload.save!(endpoint_id: endpoint.id, data: nil,
      guid: "https://www.example.com/blogs/entry1.html",
      path: Kpbb::Feed::Inbound::PayloadPath::Posts)

    req = user1.request("GET", "#{channel.relative_url}/feed/inbound/payloads", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html

    req = user1.request("GET", "#{channel.relative_url}/feed/inbound/payloads", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403
  end

  it "lists some for ranked user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user1.id)
    channelmembership1 = Kpbb::ChannelMembership.save!(user_id: user1.id, channel_id: channel.id, rank: 1)
    endpoint = Kpbb::Feed::Inbound::Endpoint.factory(creator_id: user1.id, channel_id: channel.id)
    payload = Kpbb::Feed::Inbound::Payload.save!(endpoint_id: endpoint.id, data: nil,
      guid: "https://www.example.com/blogs/entry1.html",
      path: Kpbb::Feed::Inbound::PayloadPath::Posts)

    req = user1.request("GET", "#{channel.relative_url}/feed/inbound/payloads", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html

    req = user1.request("GET", "#{channel.relative_url}/feed/inbound/payloads", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_json_res
  end
end
