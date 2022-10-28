require "../../spec_helper"

describe "Http::Posts::Show" do
  it "shows dne" do
    empty_db

    req = HTTP::Request.new("GET", "/posts/title-dne", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_404

    req = HTTP::Request.new("GET", "/posts/title-dne", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html

    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/posts/title-dne", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_404

    req = user1.request("GET", "/posts/title-dne", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html
  end

  it "shows post" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id, listed: true, public: true)
    post = Kpbb::Post.factory(channel_id: channel.id, title: "post1", creator_id: user1.id, draft: false)

    req = HTTP::Request.new("GET", post.relative_title_url, default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/Show/shows for guest"

    req = HTTP::Request.new("GET", post.relative_title_url, default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html

    req = user1.request("GET", post.relative_title_url, default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/Show/shows for user"

    req = user1.request("GET", post.relative_title_url, default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows draft post" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    user2 = TestUser.new(handle: "username2")
    user3 = TestUser.new(handle: "username3", rank: 1)
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    post = Kpbb::Post.factory(channel_id: channel.id, title: "post1", creator_id: user1.id, draft: true)

    # guest
    req = HTTP::Request.new("GET", post.relative_title_url, default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_404

    req = HTTP::Request.new("GET", post.relative_title_url, default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html

    # random user
    req = user2.request("GET", post.relative_title_url, default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_404

    req = user2.request("GET", post.relative_title_url, default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html

    # op
    req = user1.request("GET", post.relative_title_url, default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.body.should match_json_as_yaml_snapshot "Http/Posts/Show/shows draft=1 for creator"

    req = user1.request("GET", post.relative_title_url, default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html

    # admin user
    req = user3.request("GET", post.relative_title_url, default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.status_code.should eq 200
    res.body.should match_json_as_yaml_snapshot "Http/Posts/Show/shows draft=1 for admin"

    req = user3.request("GET", post.relative_title_url, default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
