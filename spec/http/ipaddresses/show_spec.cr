require "../../spec_helper"

describe "Http::Ipaddress::Show" do
  it "shows login redirect for guest when DNE" do
    empty_db
    req = HTTP::Request.new("GET", "/ipaddresses/50", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login
  end

  it "shows Forbidden for regular user when DNE" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    req = user1.request("GET", "/ipaddresses/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html
  end

  it "shows 404 for admin when DNE" do
    empty_db
    user1 = TestUser.new(handle: "username1", rank: 1)
    req = user1.request("GET", "/ipaddresses/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html
  end

  it "shows login redirect for guest" do
    empty_db
    ipaddress = Kpbb::Ipaddress.factory
    req = HTTP::Request.new("GET", "#{ipaddress.relative_url}", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login
  end

  it "shows 403 for regular user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    ipaddress = Kpbb::Ipaddress.factory
    req = user1.request("GET", "#{ipaddress.relative_url}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html
  end

  it "shows for admin user" do
    empty_db
    user1 = TestUser.new(handle: "username1", rank: 1)
    ipaddress = Kpbb::Ipaddress.factory
    # @todo admin
    req = user1.request("GET", "#{ipaddress.relative_url}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
