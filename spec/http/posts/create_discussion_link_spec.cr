require "../../spec_helper"
require "../../../src/markdown"

describe "Http::Posts::CreateDiscussionLink" do
  it "accepts optional text discussion_url" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    url = "https://www.dot.com/me"
    discussion_url = "https://news.ycombinator.com/item?id=28814144"
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "url", url
      form.add "posted", "1"
      form.add "discussion_url", discussion_url
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post = Kpbb::Post.find! get_id(res)

    link1 = Kpbb::Link.find! post.link_id.not_nil!
    link1.url.should eq url
    link1.domain_id.should be_truthy

    domain1 = Kpbb::Domain.find! link1.domain_id
    domain1.domain.should be_truthy

    link2 = Kpbb::Link.find! (post.link_id.not_nil! + 1)
    link2.url.should eq discussion_url
    link2.domain_id.should be_truthy

    domain2 = Kpbb::Domain.find! link2.domain_id
    domain2.domain.should be_truthy

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1

    (dlinks = Kpbb::DiscussionLink.all).size.should eq 1
    dlinks[0].link_id.should eq link1.id
    dlinks[0].dlink_id.should eq link2.id
  end
end
