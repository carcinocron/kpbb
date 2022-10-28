require "../../../../../spec_helper"

describe "Http::Channels::Webhook::Inbound::Endpoints::Update" do
  it "rejects user without membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints/#{endpoint.id.to_b62}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_404
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "rejects user with rank 0 membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 0)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints/#{endpoint.id.to_b62}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_404
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts empty payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints/#{endpoint.id.to_b62}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_ok
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "ignores updates to bio valid payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id, bio: "old value")
    new_bio_value = "new value"
    form = HTTP::Params.build do |form|
      form.add "bio", new_bio_value
    end
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints/#{endpoint.id.to_b62}", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    res.should be_json_200_ok
    freshendpoint = Kpbb::Webhook::Inbound::Endpoint.find!(endpoint.id)
    freshendpoint.bio.should eq endpoint.bio
    freshendpoint.bio.should_not eq new_bio_value
    freshendpoint.active.should be_true
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "ignores active=1 when active is already =1" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    form = HTTP::Params.build do |form|
      form.add "active", "1"
    end
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints/#{endpoint.id.to_b62}", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    res.should be_json_200_ok
    freshendpoint = Kpbb::Webhook::Inbound::Endpoint.find!(endpoint.id)
    freshendpoint.active.should be_true
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts deactivation" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    form = HTTP::Params.build do |form|
      form.add "active", "0"
    end
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints/#{endpoint.id.to_b62}", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    res.should be_json_200_ok
    endpoint.active.should be_true
    freshendpoint = Kpbb::Webhook::Inbound::Endpoint.find!(endpoint.id)
    freshendpoint.active.should be_false
    (channellogs = TestChannelLog.all).size.should eq 1
  end

  it "ignores active=1 when active is = 0" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id, active: false)
    form = HTTP::Params.build do |form|
      form.add "active", "1"
    end
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints/#{endpoint.id.to_b62}", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    res.should be_json_200_ok
    freshendpoint = Kpbb::Webhook::Inbound::Endpoint.find!(endpoint.id)
    freshendpoint.active.should be_false
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts updates to default_body_yaml" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    old_default_body_value = ({
      "draft"  => "0",
      "posted" => "0",
    })
    new_default_body_value = ({
      "draft"  => "1",
      "posted" => "1",
    })
    old_data_value = ({
      :body => new_default_body_value,
    }).to_json
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id, data: old_data_value)
    form = HTTP::Params.build do |form|
      form.add "default_body_yaml", new_default_body_value.to_yaml
    end
    req = user.request("POST", "#{channel.relative_url}/webhook/inbound/endpoints/#{endpoint.id.to_b62}", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    res.should be_json_200_ok
    freshendpoint = Kpbb::Webhook::Inbound::Endpoint.find!(endpoint.id)
    # we've saved one thing to disk
    freshendpoint.default_body_s.should eq new_default_body_value.to_json
    # but what gets exported to create the post has extras
    freshendpoint.default_body.should eq new_default_body_value.merge({"mask" => "None"})
    freshendpoint.active.should be_true
    (channellogs = TestChannelLog.all).size.should eq 1
    # channellogs.select { |l| l.action == Kpbb::ChannelAction::UpdateWebhookInboundEndpointDefaultBody }.size.should eq 1
    channellogs.map(&.action).should eq [
      Kpbb::ChannelAction::UpdateWebhookInboundEndpointDefaultBody,
    ] of Kpbb::ChannelAction
  end
end
