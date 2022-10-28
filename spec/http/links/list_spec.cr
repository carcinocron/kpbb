require "../../spec_helper"

describe "Http::Links::List" do
  it "shows empty for guest" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    req = HTTP::Request.new("GET", "/links", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows empty for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    req = user1.request("GET", "/links", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows active for guest" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    link_id = Kpbb::Link.save!(url: "http://www.example.com/page1")
    req = HTTP::Request.new("GET", "/links", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows active for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    link_id = Kpbb::Link.save!(url: "http://www.example.com/page1")
    req = user1.request("GET", "/links", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows not active for guest" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    url = "http://www.example.com/page1"
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    link_id = Kpbb::Link.save!(url, domain_id, active: false)
    req = HTTP::Request.new("GET", "/links", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows not active for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    url = "http://www.example.com/page1"
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    link_id = Kpbb::Link.save!(url, domain_id, active: false)
    req = user1.request("GET", "/links", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
