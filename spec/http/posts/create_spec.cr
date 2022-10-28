require "../../spec_helper"
require "../../../src/markdown"

describe "Http::Posts::Create" do
  it "redirects guest to login" do
    empty_db
    # channel = Kpbb::Channel.factory(creator_id: user.id)
    req = HTTP::Request.new("GET", "/posts/create", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login
  end

  it "shows page for user" do
    empty_db
    user = TestUser.new(handle: "username1")
    # channel = Kpbb::Channel.factory(creator_id: user.id)
    req = user.request("GET", "/posts/create", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows page for user with pre-selected channel" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user.id)
    req = user.request("GET", "/posts/create?channel_id=#{channel.id}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "rejects empty payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    # channel = Kpbb::Channel.factory(creator_id: user.id)
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_422 ({
      :title      => ["Title required."],
      :channel_id => ["Channel required."],
    })

    TestChannelLog.all.size.should eq 0
  end

  it "rejects short title" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "ab"
      form.add "channel_id", channel.id.to_b62
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :title => ["Title must be between 3 and 255 characters."],
    })
    TestChannelLog.all.size.should eq 0
  end

  it "rejects long title" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "ab" * 140
      form.add "channel_id", channel.id.to_b62
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :title => ["Title must be between 3 and 255 characters."],
    })
    TestChannelLog.all.size.should eq 0
  end

  it "rejects non-https url" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "normal title"
      form.add "url", "http://www.example.com"
      form.add "channel_id", channel.id.to_b62
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :url => ["URL must start with https://"],
    })
    TestChannelLog.all.size.should eq 0
  end

  it "accepts valid data" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post = Kpbb::Post.find! get_id(res)

    post.channel_id.should eq channel.id
    post.creator_id.should eq user.id
    post.title.should eq "cool new post"
    post.tags.should be_nil
    post.url.should be_nil
    post.link_id.should be_nil
    post.body_md.should be_nil
    post.body_html.should be_nil
    post.score.should eq 0
    post.dreplies.should eq 0
    post.posted.should eq true
    post.draft.should eq true
    post.ptype.should eq Kpbb::Post::Type::None
    # post.updated_at.should eq
    # post.created_at.should eq Time
    post.published_at.should be_nil

    TestPostTag.all.size.should eq 0_i32
    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1
  end

  it "accepts valid data with tags" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    tags_raw = "cool,new post, big fun"
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "tags", "cool,new post, big fun"
      form.add "channel_id", channel.id.to_b62
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post = Kpbb::Post.find! get_id(res)

    post.channel_id.should eq channel.id
    post.creator_id.should eq user.id
    post.title.should eq "cool new post"
    post.tags.should eq tags_raw
    post.url.should eq nil
    post.link_id.should eq nil
    post.body_md.should be_nil
    post.body_html.should be_nil
    post.score.should eq 0
    post.dreplies.should eq 0
    post.posted.should eq true
    post.draft.should eq true
    post.ptype.should eq Kpbb::Post::Type::None
    # post.updated_at.should eq
    # post.created_at.should eq Time
    post.published_at.should be_nil

    posttags = TestPostTag.all
    posttags.size.should eq 3_i32
    posttags.map(&.value).should eq ["cool", "new-post", "big-fun"]
    posttags.select { |p| p.post_id == post.id }.size.should eq 3

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1
  end

  it "accepts optional boolean value draft false" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "draft", "false"
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post = Kpbb::Post.find! get_id(res)

    post.channel_id.should eq channel.id
    post.creator_id.should eq user.id
    post.title.should eq "cool new post"
    post.url.should eq nil
    post.link_id.should eq nil
    post.body_md.should be_nil
    post.body_html.should be_nil
    post.score.should eq 0
    post.dreplies.should eq 0
    post.posted.should eq true
    post.draft.should eq false
    post.ptype.should eq Kpbb::Post::Type::None
    post.updated_at.should be_truthy
    post.created_at.should be_truthy
    post.published_at.should be_truthy
    post.published_at.not_nil!.should eq post.created_at

    (channellogs = TestChannelLog.all).size.should eq 2
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Publish }.size.should eq 1
  end

  it "accepts optional boolean value draft true" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "draft", "true"
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post = Kpbb::Post.find! get_id(res)

    post.channel_id.should eq channel.id
    post.creator_id.should eq user.id
    post.title.should eq "cool new post"
    post.url.should eq nil
    post.link_id.should eq nil
    post.body_md.should be_nil
    post.body_html.should be_nil
    post.score.should eq 0
    post.dreplies.should eq 0
    post.posted.should eq true
    post.draft.should eq true
    post.ptype.should eq Kpbb::Post::Type::None
    post.updated_at.should be_truthy
    post.created_at.should be_truthy
    post.published_at.should eq nil

    TestChannelJob.all.size.should eq 0

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1
  end

  it "rejects schedule_publish_at when already published" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "draft", "0"
      form.add "schedule_publish_at", "tomorrow"
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :schedule_publish_at => ["Post must be draft in order to schedule for publish."],
    })

    TestChannelJob.all.size.should eq 0
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "rejects schedule_publish_at when invalid value" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "draft", "1"
      form.add "schedule_publish_at", "bojangles"
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :schedule_publish_at => ["Schedule publish post at timestamp could not be interpreted."],
    })

    TestChannelJob.all.size.should eq 0
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts schedule_publish_at when valid value" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    in_30_min = (Time.utc + 30.minutes)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "draft", "1"
      form.add "schedule_publish_at", "@#{in_30_min.to_unix}"
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post = Kpbb::Post.find! get_id(res)
    post.posted.should eq true
    post.draft.should eq true
    post.ptype.should eq Kpbb::Post::Type::None
    post.published_at.should eq nil

    (channel_jobs = TestChannelJob.all).size.should eq 1
    channel_jobs[0].id.should be > 0
    channel_jobs[0].user_id.should eq user.id
    channel_jobs[0].post_id.should eq post.id
    channel_jobs[0].channel_id.should eq post.channel_id
    channel_jobs[0].comment_id.should be_nil
    channel_jobs[0].data.should be_nil
    channel_jobs[0].action.should eq Kpbb::ChannelAction::Publish
    channel_jobs[0].run_at.should be_close in_30_min, 1.second
    channel_jobs[0].run_at.should be > channel_jobs[0].created_at

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1
  end

  it "accepts optional text value body_md" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    body_md = <<-MD
      Hey everyone, me here

      # big

      [follow me](https://www.dot.com/me)
      MD
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "body_md", body_md
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post = Kpbb::Post.find! get_id(res)

    post.channel_id.should eq channel.id
    post.creator_id.should eq user.id
    post.title.should eq "cool new post"
    post.url.should eq nil
    post.link_id.should eq nil
    post.body_md.should eq body_md
    post.body_html.should eq Markdown.to_html body_md
    post.score.should eq 0
    post.dreplies.should eq 0
    post.posted.should eq true
    post.draft.should eq true
    post.ptype.should eq Kpbb::Post::Type::None
    post.updated_at.should be_truthy
    post.created_at.should be_truthy
    post.published_at.should eq nil

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1
  end

  it "rejects channel_id where channel DNE" do
    empty_db
    user = TestUser.new
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", "9000"
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :channel_id => ["Channel does not exist."],
    })

    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "rejects channel_id where channel is not public when user has no membership" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id, public: false)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :channel_id => ["Channel is not public."],
    })

    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "rejects channel_id where channel is not public when user has rank = 0" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id, public: false)
    membership = Kpbb::ChannelMembership.save!(user_id: user.id, channel_id: channel.id, rank: 0_i16)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :channel_id => ["Channel is not public."],
    })

    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts channel_id where channel is not public when user has rank > 0" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id, public: false)
    membership = Kpbb::ChannelMembership.save!(user_id: user.id, channel_id: channel.id, rank: 1_i16)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1
  end

  it "rejects channel_id where user banned is true" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    membership = Kpbb::ChannelMembership.save!(user_id: user.id, channel_id: channel.id, rank: 0_i16, banned: true)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :channel_id => ["Banned from channel."],
    })

    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts optional text value url" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    url = "https://www.dot.com/me"
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
      form.add "channel_id", channel.id.to_b62
      form.add "url", url
      form.add "posted", "1"
    end
    req = user.request("POST", "/posts", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    post = Kpbb::Post.find! get_id(res)

    post.channel_id.should eq channel.id
    post.creator_id.should eq user.id
    post.title.should eq "cool new post"
    post.url.should eq url
    post.link_id.should be_truthy
    post.body_md.should be_nil
    post.body_html.should be_nil
    post.score.should eq 0
    post.dreplies.should eq 0
    post.posted.should eq true
    post.draft.should eq true
    post.ptype.should eq Kpbb::Post::Type::None
    post.updated_at.should be_truthy
    post.created_at.should be_truthy
    post.published_at.should eq nil

    link = Kpbb::Link.find! post.link_id.not_nil!
    link.url.should eq url
    link.domain_id.should be_truthy

    domain = Kpbb::Domain.find! link.domain_id
    domain.domain.should be_truthy

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Create }.size.should eq 1
  end
end
