require "../../spec_helper"

describe "Http::Channels::Update" do
  it "accepts empty payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 1)
    req = user.request("POST", channel.relative_url, default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_ok
  end

  it "rejects public channel edit without membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id, public: true)
    req = user.request("POST", channel.relative_url, default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403
  end

  it "rejects private channel edit without membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id, public: false)
    req = user.request("POST", channel.relative_url, default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_404
  end

  it "rejects edit with rank 0 membership" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: 0)
    req = user.request("POST", channel.relative_url, default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403
  end

  it "rejects short handle" do
    empty_db
    user = TestUser.new(handle: "username1")
    form = HTTP::Params.build do |form|
      form.add "handle", "ab"
    end
    channel = Kpbb::Channel.factory(handle: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: PG_SMALLINT_MAX)
    req = user.request("POST", channel.relative_url, default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle must be between 3 and 32 characters."],
    })
  end

  it "rejects long handle" do
    empty_db
    user = TestUser.new(handle: "username1")
    form = HTTP::Params.build do |form|
      form.add "handle", "abcdefghijklmnopqrstuvwxyz0123456"
      form.add "bio", ""
    end
    channel = Kpbb::Channel.factory(handle: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: PG_SMALLINT_MAX)
    req = user.request("POST", channel.relative_url, default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle must be between 3 and 32 characters."],
    })
  end

  # it "rejects short dname", focus: true do
  #   empty_db
  #   user = TestUser.new(handle: "username1")
  #   form = HTTP::Params.build do |form|
  #     form.add "handle", "abc"
  #     form.add "dname", "ab"
  #   end
  #   channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
  #   channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: PG_SMALLINT_MAX)
  #   req = user.request("POST", channel.relative_url, default_browser_post_headers.merge!(accepts_json), form.to_s)
  #   res = process_request req
  #   res.should be_json_422 ({
  #     :dname => ["Name must be between 3 and 32 characters."],
  #   })
  # end

  it "rejects long dname" do
    empty_db
    user = TestUser.new(handle: "username1")
    form = HTTP::Params.build do |form|
      form.add "handle", "abcdefg"
      form.add "dname", "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
      form.add "bio", ""
    end
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: PG_SMALLINT_MAX)
    req = user.request("POST", channel.relative_url, default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :dname => ["Display Name must be under 48 characters."],
    })
  end

  it "accepts valid data" do
    empty_db
    user = TestUser.new(handle: "username1")
    form = HTTP::Params.build do |form|
      form.add "dname", "channel1 b"
      form.add "bio", "bio value 2"
    end
    channel = Kpbb::Channel.factory(dname: "channel1", bio: "bio value 1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: PG_SMALLINT_MAX)
    req = user.request("POST", channel.relative_url, default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok
    channel = Kpbb::Channel.find! channel.id
    # default values
    channel.public.should eq true
    channel.listed.should eq false
    channel.dname.should eq "channel1 b"
    channel.bio.should eq "bio value 2"
    Kpbb::ChannelMembership.find!(channel.id, user.id)
  end

  it "accepts optional boolean value false" do
    empty_db
    user = TestUser.new(handle: "username1")
    form = HTTP::Params.build do |form|
      form.add "public", "false"
      form.add "listed", "false"
    end
    channel = Kpbb::Channel.factory(dname: "channel1", bio: "bio value 1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: PG_SMALLINT_MAX)
    req = user.request("POST", channel.relative_url, default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok
    channel = Kpbb::Channel.find! channel.id
    channel.public.should eq false
    channel.listed.should eq false
  end

  it "accepts optional boolean value true" do
    empty_db
    user = TestUser.new(handle: "username1")
    form = HTTP::Params.build do |form|
      form.add "public", "true"
      form.add "listed", "true"
    end
    channel = Kpbb::Channel.factory(dname: "channel1", bio: "bio value 1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, rank: PG_SMALLINT_MAX)
    req = user.request("POST", channel.relative_url, default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok
    channel = Kpbb::Channel.find! channel.id
    channel.public.should eq true
    channel.listed.should eq true
  end
end
