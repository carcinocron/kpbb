require "../../spec_helper"

describe "Http::Referers::List" do
  it "lists redirect to login for guest" do
    empty_db
    req = HTTP::Request.new("GET", "/referers", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login
  end

  it "lists 403 for regular user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    referer = Kpbb::Referer.factory
    req = user1.request("GET", "/referers", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html
  end

  it "lists for admin user" do
    empty_db
    user1 = TestUser.new(handle: "username1", rank: 1)
    referer = Kpbb::Referer.factory
    # @todo admin
    req = user1.request("GET", "/referers", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
