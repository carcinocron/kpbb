require "../../../../../spec_helper"

describe "Http::Channels::Feed::Inbound::Endpoints::Create" do
  it "rejects user without membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    req = user.request("POST", "#{channel.relative_url}/feed/inbound/endpoints", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "rejects user with rank 0 membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 0)
    req = user.request("POST", "#{channel.relative_url}/feed/inbound/endpoints", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "rejects empty payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    req = user.request("POST", "#{channel.relative_url}/feed/inbound/endpoints", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_422 ({
      :url => ["URL required."],
    })
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts valid payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    bio = "for my ifttt script"
    url = "https://www.example.com/feed.xml"
    form = HTTP::Params.build do |form|
      form.add "url", url
      form.add "bio", bio
    end
    req = user.request("POST", "#{channel.relative_url}/feed/inbound/endpoints", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    res.should be_json_200
    data_returned = CreatedEndpoint.from_json res.body
    endpoint = Kpbb::Feed::Inbound::Endpoint.find! data_returned.id
    endpoint.bio.should eq bio
    endpoint.url.should eq url
    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::CreateFeedInboundEndpoint }.size.should eq 1
  end

  it "accepts valid payload then redirects correctly" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    bio = "for my ifttt script"
    url = "https://www.example.com/feed.xml"
    form = HTTP::Params.build do |form|
      form.add "url", url
      form.add "bio", bio
    end
    req = user.request("POST", "#{channel.relative_url}/feed/inbound/endpoints", default_browser_post_headers, form)
    res = process_request req
    res.status_code.should eq 302
    res.should be_redirect("/channels/channel-name/feed/inbound/endpoints/g8")
  end

  it "accepts valid payload then redirects correctly even with referer" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    bio = "for my ifttt script"
    url = "https://www.example.com/feed.xml"
    form = HTTP::Params.build do |form|
      form.add "url", url
      form.add "bio", bio
    end
    req = user.request("POST", "#{channel.relative_url}/feed/inbound/endpoints", default_browser_post_headers.merge!({
      "referer" => "https://www.example.com/yes",
    }), form)
    res = process_request req
    res.status_code.should eq 302
    res.should be_redirect("/channels/channel-name/feed/inbound/endpoints/g8")
  end
end

private struct CreatedEndpoint
  include JSON::Serializable

  property id : Int64

  # property uuid : String
  # property secret : String

  def self.from_response(res) : self
    res.status_code.should eq 201
    self.from_json res.body
  end
end
