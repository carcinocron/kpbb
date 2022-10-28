require "../../spec_helper"

describe "Http::Links::Show" do
  it "shows DNE" do
    empty_db

    req = HTTP::Request.new("GET", "/links/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html

    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/links/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html
  end

  it "shows active" do
    empty_db

    url = "http://www.example.com/page1"
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    link_id = Kpbb::Link.save!(url, domain_id, active: true)
    req = HTTP::Request.new("GET", "/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html

    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows not active" do
    empty_db

    url = "http://www.example.com/page1"
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    link_id = Kpbb::Link.save!(url, domain_id, active: false)
    req = HTTP::Request.new("GET", "/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login

    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html

    user2 = TestUser.new(handle: "username2", rank: 1)

    req = user2.request("GET", "/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
