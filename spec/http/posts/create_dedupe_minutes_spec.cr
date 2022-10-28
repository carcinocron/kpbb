require "../../spec_helper"
require "../../../src/markdown"

describe "Http::Posts::CreateDedupeMinutes" do
  it "accepts valid data" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "draft", "0"
      form.add "url", "https://www.example.com/page1.html"
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post1 = Kpbb::Post.find! get_id(res)
    (channellogs = TestChannelLog.all).size.should eq 2
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1

    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "draft", "0"
      form.add "url", "https://www.example.com/page1.html"
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post2 = Kpbb::Post.find! get_id(res)
    (channellogs = TestChannelLog.all).size.should eq 4
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 2

    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "url", "https://www.example.com/page1.html"
      form.add "draft", "0"
      form.add "dedupe_minutes", "1"
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :url             => ["URL was already submitted recently."],
      :duplicate_of_id => [post2.id.to_s],
    })
    # post = Kpbb::Post.find! get_id(res)
    (channellogs = TestChannelLog.all).size.should eq 4
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 2
  end
end
