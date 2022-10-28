require "../../../../../spec_helper"

describe "Http::Channels::Webhook::Inbound::Endpoints::Create" do
  it "rejects user without membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "rejects user with rank 0 membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 0)
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts empty payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200
    data_returned = CreatedEndpoint.from_json res.body
    endpoint = Kpbb::Webhook::Inbound::Endpoint.find! data_returned.id
    hashed_secret = Crypto::Bcrypt::Password.new(endpoint.secret)
    hashed_secret.verify(data_returned.secret).should eq true
    endpoint.bio.should be_nil
    (channellogs = TestChannelLog.all).size.should eq 1
  end

  it "accepts valid payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    bio = "for my ifttt script"
    form = HTTP::Params.build do |form|
      form.add "bio", bio
    end
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    res.should be_json_200
    data_returned = CreatedEndpoint.from_json res.body
    endpoint = Kpbb::Webhook::Inbound::Endpoint.find! data_returned.id
    hashed_secret = Crypto::Bcrypt::Password.new(endpoint.secret)
    hashed_secret.verify(data_returned.secret).should eq true
    endpoint.bio.should eq bio
    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::CreateWebhookInboundEndpoint }.size.should eq 1
  end

  it "shows special created page with secret" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    bio = "for my ifttt script"
    form = HTTP::Params.build do |form|
      form.add "bio", bio
    end

    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints", default_browser_post_headers, form)
    res = process_request req
    res.status_code.should eq 200
    res.should be_html

    endpoint = Kpbb::Webhook::Inbound::Endpoint.last?.not_nil!
    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::CreateWebhookInboundEndpoint }.size.should eq 1
  end
end

private struct CreatedEndpoint
  include JSON::Serializable

  property id : Int64
  property uuid : String
  property secret : String

  def self.from_response(res) : self
    res.status_code.should eq 201
    self.from_json res.body
  end
end
