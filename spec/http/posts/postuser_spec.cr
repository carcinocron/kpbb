require "../../spec_helper"

describe "Http::Posts::Kpbb::PostUser" do
  it "accepts empty payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id)
    postuser_id = Kpbb::PostUser.save!(post_id: channel.id, user_id: user.id)
    req = user.request("POST", "#{post.relative_url}/users/#{user.id.to_b62}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_ok
  end

  it "accepts saved" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id)
    postuser_id = Kpbb::PostUser.save!(post_id: channel.id, user_id: user.id, saved_at: nil)
    form = HTTP::Params.build do |form|
      form.add "saved", "true"
    end
    req = user.request("POST", "#{post.relative_url}/users/#{user.id.to_b62}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok
    postusers = Kpbb::PostUser.find!(postuser_id)
    postusers.saved.should eq true
    postusers.saved_at.should be_truthy
  end

  it "accepts unsaved" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id)
    postuser_id = Kpbb::PostUser.save!(post_id: channel.id, user_id: user.id, saved_at: Time.utc)
    form = HTTP::Params.build do |form|
      form.add "saved", "false"
    end
    req = user.request("POST", "#{post.relative_url}/users/#{user.id.to_b62}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok
    postusers = Kpbb::PostUser.find!(postuser_id)
    postusers.saved.should eq false
    postusers.saved_at.should be_nil
  end

  it "rejects setting another user's saved" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user1.id)
    postuser_id = Kpbb::PostUser.save!(post_id: channel.id, user_id: user1.id)

    req = user2.request("POST", "#{post.relative_url}/users/#{user1.id.to_b62}", default_browser_post_headers.merge!(accepts_json), "saved=true")
    res = process_request req
    res.should be_json_403
  end

  it "rejects setting another user's saved by a mod" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    user2 = TestUser.new(handle: "username2")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user1.id)
    postuser_id = Kpbb::PostUser.save!(post_id: channel.id, user_id: user1.id)

    req = user1.request("POST", "#{post.relative_url}/users/#{user2.id.to_b62}", default_browser_post_headers.merge!(accepts_json), "saved=true")
    res = process_request req
    res.should be_json_403
  end
end
