require "../../spec_helper"

describe "Http::Domains::List" do
  it "shows empty for guest" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    req = HTTP::Request.new("GET", "/domains", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows empty for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    req = user1.request("GET", "/domains", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows active for guest" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    domain_id = Kpbb::Domain.save!(domain: "example.com", active: true)
    req = HTTP::Request.new("GET", "/domains", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows active for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    domain_id = Kpbb::Domain.save!(domain: "example.com", active: true)
    req = user1.request("GET", "/domains", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows not active for guest" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    domain_id = Kpbb::Domain.save!(domain: "example.com", active: true)
    req = HTTP::Request.new("GET", "/domains", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows not active for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    domain_id = Kpbb::Domain.save!(domain: "example.com", active: true)
    req = user1.request("GET", "/domains", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
