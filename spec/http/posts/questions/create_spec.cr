require "../../../spec_helper"

describe "Http::Posts::Questions::Create" do
  it "rejects question ptype without parent post" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user1.id)
    post = Kpbb::Post.factory(channel_id: channel.id, title: "post1", creator_id: user1.id, draft: false)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new question"
      form.add "channel_id", channel.id.to_b62
      # form.add "parent_id", post.id.to_b62
      form.add "ptype", Kpbb::Post::Type::Question.to_s
    end
    req = user1.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :ptype => ["Post with parent requires post type."],
    })

    TestChannelLog.all.size.should eq 0
  end

  it "accepts valid data" do
    empty_db
    user1 = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user1.id)
    parentpost1 = Kpbb::Post.factory(channel_id: channel.id, title: "parentpost11", creator_id: user1.id, draft: false)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new question"
      form.add "channel_id", channel.id.to_b62
      form.add "parent_id", parentpost1.id.to_b62
      form.add "ptype", Kpbb::Post::Type::Question.to_s
      form.add "posted", "1"
    end
    req = user1.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post = Kpbb::Post.find! get_id(res)

    post.channel_id.should eq channel.id
    post.creator_id.should eq user1.id
    post.title.should eq "cool new question"
    post.tags.should eq nil
    post.url.should eq nil
    post.link_id.should eq nil
    post.body_md.should eq nil
    post.body_html.should eq nil
    post.score.should eq 0
    post.dreplies.should eq 0
    post.posted.should eq true
    post.draft.should eq true
    post.ptype.should eq Kpbb::Post::Type::Question
    # post.updated_at.should eq
    # post.created_at.should eq Time
    post.published_at.should be_nil

    TestPostTag.all.size.should eq 0_i32
    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1
  end
end
