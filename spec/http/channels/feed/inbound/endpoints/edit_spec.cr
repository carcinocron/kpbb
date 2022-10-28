require "../../../../../spec_helper"

describe "Http::Channels::Feed::Inbound::Endpoints::Edit" do
  it "rejects user without membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    endpoint = Kpbb::Feed::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)

    req = HTTP::Request.new("GET", "#{channel.relative_url}/feed/inbound/endpoints/#{endpoint.id.to_b62}/edit", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_401

    req = HTTP::Request.new("GET", "#{channel.relative_url}/feed/inbound/endpoints/#{endpoint.id.to_b62}/edit", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login

    req = user.request("GET", "#{channel.relative_url}/feed/inbound/endpoints/#{endpoint.id.to_b62}/edit", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403

    req = user.request("GET", "#{channel.relative_url}/feed/inbound/endpoints/#{endpoint.id.to_b62}/edit", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html
  end

  it "rejects user with rank 0 membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 0)
    endpoint = Kpbb::Feed::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)

    req = user.request("GET", "#{channel.relative_url}/feed/inbound/endpoints/#{endpoint.id.to_b62}/edit", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403

    req = user.request("GET", "#{channel.relative_url}/feed/inbound/endpoints/#{endpoint.id.to_b62}/edit", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html
  end

  it "shows for valid user" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    endpoint = Kpbb::Feed::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)

    req = user.request("GET", "#{channel.relative_url}/feed/inbound/endpoints/#{endpoint.id.to_b62}/edit", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_just_id

    req = user.request("GET", "#{channel.relative_url}/feed/inbound/endpoints/#{endpoint.id.to_b62}/edit", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
