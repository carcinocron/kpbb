require "../../../spec_helper"

describe "Http::Posts::Comments::Create" do
  it "rejects comment without content" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user1.id)
    post = Kpbb::Post.factory(channel_id: channel.id, title: "post1", creator_id: user1.id, draft: false)
    form = HTTP::Params.build do |form|
      form.add "body_md", ""
      form.add "channel_id", channel.id.to_b62
      form.add "parent_id", post.id.to_b62
      form.add "ptype", Kpbb::Post::Type::Comment.to_s
    end
    req = user1.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :body_md => ["Cannot be empty."],
    })

    TestChannelLog.all.size.should eq 0
  end

  it "rejects comment ptype without parent post" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user1.id)
    post = Kpbb::Post.factory(channel_id: channel.id, title: "post1", creator_id: user1.id, draft: false)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new comment reply"
      form.add "channel_id", channel.id.to_b62
      # form.add "parent_id", post.id.to_b62
      form.add "ptype", Kpbb::Post::Type::Comment.to_s
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
    expected_body_md = "cool new comment reply"
    form = HTTP::Params.build do |form|
      form.add "body_md", expected_body_md
      form.add "channel_id", channel.id.to_b62
      form.add "parent_id", parentpost1.id.to_b62
      form.add "ptype", Kpbb::Post::Type::Comment.to_s
    end
    req = user1.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post = Kpbb::Post.find! get_id(res)

    post.channel_id.should eq channel.id
    post.creator_id.should eq user1.id
    post.title.should eq nil
    post.tags.should eq nil
    post.url.should eq nil
    post.link_id.should eq nil
    post.body_md.should eq expected_body_md
    post.body_html.should eq Markdown.to_html(expected_body_md)
    post.score.should eq 0
    post.dreplies.should eq 0
    post.posted.should eq false
    post.draft.should eq true
    post.ptype.should eq Kpbb::Post::Type::Comment
    # post.updated_at.should eq
    # post.created_at.should eq Time
    post.published_at.should be_nil

    TestPostTag.all.size.should eq 0_i32
    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1
  end
end
