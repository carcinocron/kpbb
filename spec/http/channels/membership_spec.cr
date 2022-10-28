require "../../spec_helper"

describe "Http::Channels::Membership" do
  it "accepts empty payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id)
    req = user.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_ok
  end

  it "accepts follow" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, follow: false)
    form = HTTP::Params.build do |form|
      form.add "follow", "true"
    end
    req = user.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user.id.to_base62}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok
    channelmembership = Kpbb::ChannelMembership.find!(channelmembership.id)
    channelmembership.follow.should eq true
  end

  it "accepts unfollow" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user.id, follow: true)
    form = HTTP::Params.build do |form|
      form.add "follow", "false"
    end
    req = user.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user.id.to_base62}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok
    channelmembership = Kpbb::ChannelMembership.find!(channelmembership.id)
    channelmembership.follow.should eq false
  end

  it "rejects setting another user's follow" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX)

    req = user2.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user1.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "follow=true")
    res = process_request req
    res.should be_json_403
  end

  it "rejects setting another user's follow by a mod" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    channelmembership = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX)

    req = user1.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user2.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "follow=true")
    res = process_request req
    res.should be_json_422 ({
      :follow => ["You can't edit another user's follow."],
    })
  end

  it "rejects setting another user's banned" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    req = user2.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user1.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "banned=true")
    res = process_request req
    res.should be_json_403

    user1cm = Kpbb::ChannelMembership.find?(channel_id: channel.id, user_id: user1.id)
    user1cm.should be_nil # not created because rejected
  end

  it "rejects setting another user's banned" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    req = user2.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user1.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "banned=true")
    res = process_request req
    res.should be_json_403
  end

  it "accepts setting another user's banned by a mod" do
    empty_db
    user1 = TestUser.new(handle: "modusername1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    user1cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX)
    req = user1.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user2.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "banned=true")
    res = process_request req
    res.should be_json_200_ok

    user2cm = Kpbb::ChannelMembership.find!(channel_id: channel.id, user_id: user2.id)
    user2cm.banned.should eq true
  end

  it "rejects setting a mod's self banned" do
    empty_db
    user1 = TestUser.new(handle: "modusername1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    user1cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX)
    req = user1.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user1.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "banned=true")
    res = process_request req
    res.should be_json_422 ({
      :banned => ["You can't ban yourself."],
    })
  end

  it "rejects setting a mod's banned by a lower ranked mod" do
    empty_db
    user1 = TestUser.new(handle: "modusername1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    user1cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX - 1)
    user2cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user2.id, rank: PG_SMALLINT_MAX)
    req = user1.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user2.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "banned=true")
    res = process_request req
    res.status_code.should eq 422
    res.should be_json_422 ({
      :banned => ["You can only ban lower ranked users (channel rank)."],
    })
  end

  it "accepts setting a mod's banned by a higher ranked mod" do
    empty_db
    user1 = TestUser.new(handle: "modusername1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    user1cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX)
    user2cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user2.id, rank: PG_SMALLINT_MAX - 1)
    req = user1.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user2.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "banned=true")
    res = process_request req
    res.should be_json_200_ok

    user2cm = Kpbb::ChannelMembership.find!(user2cm.id)
    user2cm.banned.should eq true
    user2cm.rank.should eq 0
  end

  it "accepts setting a user's banned=false by a mod" do
    empty_db
    user1 = TestUser.new(handle: "modusername1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    user1cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX)
    user2cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user2.id, banned: true)
    req = user1.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user2.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "banned=false")
    res = process_request req
    res.should be_json_200_ok

    user2cm = Kpbb::ChannelMembership.find!(user2cm.id)
    user2cm.banned.should eq false
    user2cm.rank.should eq 0
  end

  it "rejects setting another user's rank" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    req = user2.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user1.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "rank=20")
    res = process_request req
    res.should be_json_403

    user1cm = Kpbb::ChannelMembership.find?(channel_id: channel.id, user_id: user1.id)
    user1cm.should be_nil # not created because rejected
  end

  it "rejects setting another user's rank" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    req = user2.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user1.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "rank=20")
    res = process_request req
    res.should be_json_403
  end

  it "accepts setting another user's rank by a mod" do
    empty_db
    user1 = TestUser.new(handle: "modusername1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    user1cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX)
    req = user1.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user2.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "rank=20")
    res = process_request req
    res.should be_json_200_ok

    user2cm = Kpbb::ChannelMembership.find!(channel_id: channel.id, user_id: user2.id)
    user2cm.rank.should eq 20
  end

  it "rejects setting a mod's self rank" do
    empty_db
    user1 = TestUser.new(handle: "modusername1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    user1cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX)
    req = user1.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user1.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "rank=20")
    res = process_request req
    res.status_code.should eq 422
    res.should be_json_422 ({
      :rank => ["You can't set rank on yourself."],
    })
  end

  it "rejects setting a mod's rank by a lower ranked mod" do
    empty_db
    user1 = TestUser.new(handle: "modusername1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    user1cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX - 1)
    user2cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user2.id, rank: PG_SMALLINT_MAX)
    req = user1.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user2.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "rank=20")
    res = process_request req
    res.status_code.should eq 422
    res.should be_json_422 ({
      :rank => ["You can only set rank on lower ranked users (channel rank)."],
    })
  end

  it "accepts setting a mod's rank by a higher ranked mod" do
    empty_db
    user1 = TestUser.new(handle: "modusername1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    user1cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX)
    user2cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user2.id, rank: PG_SMALLINT_MAX - 1)
    req = user1.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user2.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "rank=20")
    res = process_request req
    res.should be_json_200_ok

    user2cm = Kpbb::ChannelMembership.find!(user2cm.id)
    user2cm.rank.should eq 20
  end

  it "accepts setting a user's rank=false by a mod" do
    empty_db
    user1 = TestUser.new(handle: "modusername1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    user1cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user1.id, rank: PG_SMALLINT_MAX)
    user2cm = Kpbb::ChannelMembership.save!(channel_id: channel.id, user_id: user2.id, rank: 20)
    req = user1.request("POST", "/channelmembership?channel_id=#{channel.id.to_base62}&user_id=#{user2.id.to_base62}", default_browser_post_headers.merge!(accepts_json), "rank=19")
    res = process_request req
    res.should be_json_200_ok

    user2cm = Kpbb::ChannelMembership.find!(user2cm.id)
    user2cm.rank.should eq 19
  end
end
