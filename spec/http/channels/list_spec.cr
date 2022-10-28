require "../../spec_helper"

describe "Http::Channels::List" do
  it "lists empty for guest" do
    empty_db
    req = HTTP::Request.new("GET", "/channels", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html

    req = HTTP::Request.new("GET", "/channels", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Channels/List/lists empty for guest"
  end

  it "lists empty for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/channels", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Channels/List/lists empty for user"

    req = user1.request("GET", "/channels", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "lists some for guest" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)

    req = HTTP::Request.new("GET", "/channels", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Channels/List/lists some for guest"

    req = HTTP::Request.new("GET", "/channels", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "lists some for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id, listed: true, public: true)
    channel2 = Kpbb::Channel.factory(dname: "channel2", creator_id: user1.id, listed: false, public: true)

    req = user1.request("GET", "/channels", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Channels/List/lists some for user"

    req = user1.request("GET", "/channels", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "lists some hidden=1 for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel1 = Kpbb::Channel.factory(handle: "channel1", creator_id: user1.id, listed: true, public: true)
    channel2 = Kpbb::Channel.factory(handle: "channel2", creator_id: user1.id, listed: true, public: true)
    hiddenchannel = Kpbb::Channel.factory(handle: "hiddenchannel", creator_id: user1.id, listed: true, public: true)

    channelmembership_id = Kpbb::ChannelMembership.save!(channel_id: channel1.id, user_id: user1.id, hidden_at: nil)
    # channelmembership_id = Kpbb::ChannelMembership.save!(channel_id: channel2.id, user_id: user1.id, hidden_at: nil)
    channelmembership_id = Kpbb::ChannelMembership.save!(channel_id: hiddenchannel.id, user_id: user1.id, hidden_at: Time.utc)

    req = user1.request("GET", "/channels?hidden=1", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Channels/List/lists some hidden=1 for user"

    req = user1.request("GET", "/channels?hidden=1", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "lists some following=1 for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id, listed: true, public: true)
    followedchannel = Kpbb::Channel.factory(dname: "channel followed by user", creator_id: user1.id, listed: true, public: true)
    channelmembership_id = Kpbb::ChannelMembership.save!(channel_id: followedchannel.id, user_id: user1.id, follow: true)

    req = user1.request("GET", "/channels?following=1", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Channels/List/lists some following=1 for user"

    req = user1.request("GET", "/channels?following=1", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "lists some ranked=1 for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id, listed: true, public: true)
    rankedchannel = Kpbb::Channel.factory(dname: "channel followed by user", creator_id: user1.id, listed: true, public: true)
    channelmembership_id = Kpbb::ChannelMembership.save!(channel_id: rankedchannel.id, user_id: user1.id, rank: 1)

    req = user1.request("GET", "/channels?ranked=1", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Channels/List/lists some ranked=1 for user"

    req = user1.request("GET", "/channels?ranked=1", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
