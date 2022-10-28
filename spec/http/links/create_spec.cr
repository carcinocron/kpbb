require "../../spec_helper"

describe "Http::Links::Create" do
  it "401 for guests" do
    empty_db

    req = HTTP::Request.new("POST", "/links", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_401

    req = HTTP::Request.new("GET", "/links/create", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login
  end

  it "403 for users" do
    empty_db
    user1 = TestUser.new(handle: "username1")

    req = user1.request("POST", "/links", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403

    req = user1.request("POST", "/links", default_browser_post_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html

    req = user1.request("GET", "/links/create", default_browser_post_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html
  end

  it "405 for admins" do
    empty_db
    user1 = TestUser.new(handle: "username1", rank: 1)

    req = user1.request("POST", "/links", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_405

    req = user1.request("POST", "/links", default_browser_post_headers, "")
    res = process_request req
    res.status_code.should eq 405
    res.should be_html

    req = user1.request("GET", "/links/create", default_browser_post_headers, "")
    res = process_request req
    res.status_code.should eq 405
    res.should be_html
  end
end
