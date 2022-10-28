require "../../spec_helper"
require "../../../src/markdown"

describe "Http::Posts::Update" do
  it "accepts empty payload" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id)
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_ok

    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "rejects short title" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "ab"
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.status_code.should eq 422
    res.should be_json_422 ({
      :title => ["Title must be between 3 and 255 characters."],
    })

    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "rejects long title" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "ab" * 140
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :title => ["Title must be between 3 and 255 characters."],
    })

    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "rejects non-https url" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "url", "http://www.example.com"
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :url => ["URL must start with https://"],
    })

    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "ignores changing channel_id" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    channel2 = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "channel_id", channel2.id.to_b62
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok

    freshpost = Kpbb::Post.find!(post.id)
    freshpost.id.should eq post.id
    post.channel_id.should eq freshpost.channel_id

    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts valid title change" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "title", "cool new post"
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok

    freshpost = Kpbb::Post.find!(post.id)
    freshpost.id.should eq post.id
    freshpost.title.should eq "cool new post"
    freshpost.updated_at.should be > post.updated_at

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::UpdateTitle }.size.should eq 1
  end

  it "accepts valid tags change" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    TestPostTag.all.size.should eq 0_i32
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "tags", "cool, new tags"
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok

    freshpost = Kpbb::Post.find!(post.id)
    freshpost.id.should eq post.id
    freshpost.tags.should eq "cool, new tags"
    freshpost.updated_at.should be > post.updated_at

    posttags = TestPostTag.all
    posttags.size.should eq 2_i32
    posttags.map(&.value).should eq ["cool", "new-tags"]
    posttags.select { |p| p.post_id == freshpost.id }.size.should eq 2

    form = HTTP::Params.build do |form|
      form.add "tags", ""
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok

    TestPostTag.all.size.should eq 0_i32
    (channellogs = TestChannelLog.all).size.should eq 2
    channellogs.select { |l| l.action == Kpbb::ChannelAction::UpdateTags }.size.should eq 2
  end

  it "accepts optional boolean value draft false" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(draft: true, channel_id: channel.id, creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "draft", "false"
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok

    freshpost = Kpbb::Post.find!(post.id)
    freshpost.id.should eq post.id

    post.draft.should eq true
    post.published_at.should be_nil
    post.ptype.should eq Kpbb::Post::Type::None

    freshpost.draft.should eq false
    freshpost.published_at.should be_truthy

    freshpost.updated_at.should be > post.updated_at

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Publish }.size.should eq 1
  end

  it "accepts optional boolean value draft true" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(draft: false, published_at: Time.local, channel_id: channel.id, creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "draft", "true"
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok

    freshpost = Kpbb::Post.find!(post.id)
    freshpost.id.should eq post.id

    post.draft.should eq false
    post.published_at.should be_truthy
    post.ptype.should eq Kpbb::Post::Type::None

    freshpost.draft.should eq true
    freshpost.published_at.should be_nil

    freshpost.updated_at.should be > post.updated_at

    TestChannelJob.all.size.should eq 0
    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Unpublish }.size.should eq 1
  end

  it "rejects schedule_publish_at when already published" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(draft: false, published_at: Time.local, channel_id: channel.id, creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "draft", "0"
      form.add "schedule_publish_at", "tomorrow"
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :schedule_publish_at => ["Post must be draft in order to schedule for publish."],
    })

    TestChannelJob.all.size.should eq 0
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts schedule_publish_at when valid value" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(draft: false, published_at: Time.local, channel_id: channel.id, creator_id: user.id)
    in_30_min = (Time.utc + 30.minutes)
    form = HTTP::Params.build do |form|
      form.add "channel_id", channel.id.to_b62
      form.add "draft", "1"
      form.add "schedule_publish_at", "@#{in_30_min.to_unix}"
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok

    freshpost = Kpbb::Post.find!(post.id)
    freshpost.id.should eq post.id

    freshpost.posted.should eq true
    freshpost.draft.should eq true
    freshpost.published_at.should eq nil

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
    channellogs.select { |l| l.action == Kpbb::ChannelAction::Unpublish }.size.should eq 1
  end

  it "rejects schedule_publish_at when invalid value" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(draft: false, published_at: Time.local, channel_id: channel.id, creator_id: user.id)
    form = HTTP::Params.build do |form|
      form.add "draft", "1"
      form.add "schedule_publish_at", "bojangles"
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :schedule_publish_at => ["Schedule publish post at timestamp could not be interpreted."],
    })

    TestChannelJob.all.size.should eq 0
    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts optional text value body_md" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id)
    body_md = <<-MD
      Hey everyone, me here

      # big

      [follow me](https://www.dot.com/me)
      MD
    form = HTTP::Params.build do |form|
      form.add "body_md", body_md
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok

    freshpost = Kpbb::Post.find!(post.id)
    freshpost.id.should eq post.id

    post.body_md.should be_nil
    post.body_html.should be_nil

    freshpost.body_md.should eq body_md
    freshpost.body_html.should eq Markdown.to_html(body_md)

    freshpost.updated_at.should be > post.updated_at

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::UpdateBodyMd }.size.should eq 1
  end

  it "rejects editing other user's post" do
    empty_db
    user = TestUser.new(handle: "handle1")
    user2 = TestUser.new(handle: "handle2")
    channel = Kpbb::Channel.factory(creator_id: user2.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user2.id)
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403

    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts admin editing other user's post payload" do
    empty_db
    user = TestUser.new(handle: "handle1", rank: 1)
    user2 = TestUser.new(handle: "handle2")
    channel = Kpbb::Channel.factory(creator_id: user2.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user2.id)
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_ok

    (channellogs = TestChannelLog.all).size.should eq 0
  end

  it "accepts optional text value url" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(channel_id: channel.id, creator_id: user.id, title: "cool new post")
    url = "https://www.dot.com/me"
    form = HTTP::Params.build do |form|
      form.add "url", url
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.status_code.should eq 200
    body = res.should be_json_200_ok
    freshpost = Kpbb::Post.find! post.id

    freshpost.channel_id.should eq channel.id
    freshpost.creator_id.should eq user.id
    freshpost.title.should eq post.title
    freshpost.url.should eq url
    post.link_id.should be_nil
    freshpost.link_id.should be_truthy
    freshpost.body_md.should eq post.body_md
    freshpost.body_html.should eq post.body_html
    freshpost.score.should eq post.score
    freshpost.dreplies.should eq post.dreplies
    freshpost.posted.should eq post.posted
    freshpost.draft.should eq post.draft
    freshpost.updated_at.should be > post.updated_at
    freshpost.created_at.should eq post.created_at
    freshpost.published_at.should eq post.published_at

    link = Kpbb::Link.find! freshpost.link_id.not_nil!
    link.url.should eq url
    link.domain_id.should be_truthy

    domain = Kpbb::Domain.find! link.domain_id
    domain.domain.should be_truthy

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::UpdateUrl }.size.should eq 1
  end

  it "accepts optional value mask=0" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(draft: false, published_at: Time.local, channel_id: channel.id, creator_id: user.id, mask: Kpbb::Mask::Mask::Channel)
    new_mask_value = Kpbb::Mask::Mask::None
    form = HTTP::Params.build do |form|
      form.add "mask", new_mask_value.to_s
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok

    freshpost = Kpbb::Post.find!(post.id)
    freshpost.id.should eq post.id

    post.mask.should eq Kpbb::Mask::Mask::Channel
    freshpost.mask.should eq Kpbb::Mask::Mask::None
    freshpost.updated_at.should be > post.updated_at

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::UpdateMask }.size.should eq 1
  end

  it "accepts optional value mask=1" do
    empty_db
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(draft: false, published_at: Time.local, channel_id: channel.id, creator_id: user.id, mask: Kpbb::Mask::Mask::None)
    new_mask_value = Kpbb::Mask::Mask::Channel
    form = HTTP::Params.build do |form|
      form.add "mask", new_mask_value.value.to_s
    end
    req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_ok

    freshpost = Kpbb::Post.find!(post.id)
    freshpost.id.should eq post.id

    post.mask.should eq Kpbb::Mask::Mask::None
    freshpost.mask.should eq new_mask_value
    freshpost.updated_at.should be > post.updated_at

    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs.select { |l| l.action == Kpbb::ChannelAction::UpdateMask }.size.should eq 1
  end
end
