require "../../spec_helper"

describe "Http::Posts::List" do
  it "lists empty" do
    empty_db

    req = HTTP::Request.new("GET", "/posts", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/List/lists empty for guest"

    req = HTTP::Request.new("GET", "/posts", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html

    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/posts", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/List/lists empty for user"

    req = user1.request("GET", "/posts", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "lists some" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id, listed: true, public: true)
    post = Kpbb::Post.factory(channel_id: channel.id, title: "post1", creator_id: user1.id, draft: false)

    req = HTTP::Request.new("GET", "/posts", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/List/lists some for guest"

    req = HTTP::Request.new("GET", "/posts", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html

    req = user1.request("GET", "/posts", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/List/lists some for user"

    req = user1.request("GET", "/posts", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "lists some hidden=1" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    post = Kpbb::Post.factory(channel_id: channel.id, title: "post1", creator_id: user1.id, draft: false)
    hiddenpost = Kpbb::Post.factory(channel_id: channel.id, title: "post2 hidden", creator_id: user1.id, draft: false)
    postuser1 = Kpbb::PostUser.save!(post_id: post.id, user_id: user1.id, hidden_at: nil)
    postuser2 = Kpbb::PostUser.save!(post_id: post.id, user_id: user1.id, hidden_at: Time.utc)

    req = user1.request("GET", "/posts?hidden=1", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/List/lists some hidden=1 for user"

    req = user1.request("GET", "/posts?hidden=1", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "lists some saved=1" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    post = Kpbb::Post.factory(channel_id: channel.id, title: "post1", creator_id: user1.id, draft: false)
    savedpost = Kpbb::Post.factory(channel_id: channel.id, title: "post2 saved", creator_id: user1.id, draft: false)
    postuser1 = Kpbb::PostUser.save!(post_id: post.id, user_id: user1.id, saved_at: nil)
    postuser2 = Kpbb::PostUser.save!(post_id: post.id, user_id: user1.id, saved_at: Time.utc)

    req = user1.request("GET", "/posts?saved=1", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/List/lists some saved=1 for user"

    req = user1.request("GET", "/posts?saved=1", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "lists some draft=1" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    post = Kpbb::Post.factory(channel_id: channel.id, title: "post1", creator_id: user1.id, draft: false)
    draftpost = Kpbb::Post.factory(channel_id: channel.id, title: "post2 draft", creator_id: user1.id, draft: true)

    req = user1.request("GET", "/posts?draft=1", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/List/lists some draft=1 for user"

    req = user1.request("GET", "/posts?draft=1", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "lists some channel_id=X" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel1 = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    channel2 = Kpbb::Channel.factory(dname: "channel2", creator_id: user1.id)
    post = Kpbb::Post.factory(channel_id: channel1.id, title: "post1", creator_id: user1.id, draft: false)
    otherpost = Kpbb::Post.factory(channel_id: channel2.id, title: "post2 other channel", creator_id: user1.id, draft: false)

    req = user1.request("GET", "/posts?channel_id=#{channel1.id.to_b62}", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/List/lists some channel_id=X for user"

    req = user1.request("GET", "/posts?channel_id=#{channel1.id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "lists some link=X" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    # domain_id = Kpbb::Domain.save!(domain: "example.com")
    url1 = "https://www.example.com/expected-url"
    url2 = "https://www.example.com/other-url"
    link1_id = Kpbb::Link.save!(url1)
    link2_id = Kpbb::Link.save!(url2)
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id, listed: true, public: true)
    post_with_link = Kpbb::Post.factory(channel_id: channel.id, title: "post1", url: url1, link_id: link1_id, creator_id: user1.id, draft: false)
    post_no_link = Kpbb::Post.factory(channel_id: channel.id, title: "post2: post_no_link", creator_id: user1.id, draft: false)
    post_other_link = Kpbb::Post.factory(channel_id: channel.id, title: "post3: other link", url: url2, link_id: link2_id, creator_id: user1.id, draft: false)

    req = user1.request("GET", "/posts?url=#{post_with_link.url}", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/List/lists some link=X for user"

    req = user1.request("GET", "/posts?url=#{post_with_link.url}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
