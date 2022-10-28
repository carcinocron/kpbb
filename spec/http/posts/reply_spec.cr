require "../../spec_helper"

describe "Http::Posts::Reply" do
  it "handles reply page for post dne" do
    empty_db

    req = HTTP::Request.new("GET", "/posts/dne/reply", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_401

    req = HTTP::Request.new("GET", "/posts/dne/reply", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login

    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/posts/dne/reply", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_501

    req = user1.request("GET", "/posts/dne/reply", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html
  end

  it "shows reply page for post" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id, listed: true, public: true)
    post = Kpbb::Post.factory(channel_id: channel.id, title: "post1", creator_id: user1.id, draft: false)

    req = HTTP::Request.new("GET", "#{post.relative_title_url}/reply", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_401

    req = HTTP::Request.new("GET", "#{post.relative_title_url}/reply", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login

    req = user1.request("GET", "#{post.relative_title_url}/reply", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_501

    req = user1.request("GET", "#{post.relative_title_url}/reply", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
