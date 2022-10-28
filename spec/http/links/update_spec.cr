require "../../spec_helper"

describe "Http::Links::Create" do
  it "401 for guests" do
    empty_db
    link_id = Kpbb::Link.save!(url: "http://www.example.com/page1")

    req = HTTP::Request.new("POST", "/links/#{link_id.to_b62}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_401

    req = HTTP::Request.new("GET", "/links/#{link_id.to_b62}/edit", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login
  end

  it "403 for users" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    link_id = Kpbb::Link.save!(url: "http://www.example.com/page1") # , active: true)

    req = user1.request("POST", "/links/#{link_id.to_b62}", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_403

    req = user1.request("GET", "/links/#{link_id.to_b62}/edit", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html
  end

  it "admins can toggle active" do
    empty_db
    user1 = TestUser.new(handle: "username1", rank: 1)
    link_id = Kpbb::Link.save!(url: "http://www.example.com/page1") # , active: true)

    req = user1.request("POST", "/links/#{link_id.to_b62}", default_browser_post_headers.merge!(accepts_json), "active=false")
    res = process_request req
    res.status_code.should eq 200
    res.should be_json_200_ok

    req = user1.request("POST", "/links/#{link_id.to_b62}", default_browser_post_headers.merge!(accepts_json), "active=true")
    res = process_request req
    res.should be_json_200_ok

    req = user1.request("GET", "/links/#{link_id.to_b62}/edit", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
