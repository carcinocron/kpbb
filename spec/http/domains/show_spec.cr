require "../../spec_helper"

describe "Http::Domains::Show" do
  it "shows DNE" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    req = HTTP::Request.new("GET", "/domains/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html

    req = user1.request("GET", "/domains/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html
  end

  it "shows active" do
    empty_db

    user1 = TestUser.new(handle: "username1")
    domain_id = Kpbb::Domain.save!(domain: "example.com")

    req = HTTP::Request.new("GET", "/domains/#{domain_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html

    req = user1.request("GET", "/domains/#{domain_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows not active" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    domain_id = Kpbb::Domain.save!(domain: "example.com", active: false)

    req = HTTP::Request.new("GET", "/domains/#{domain_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html

    req = user1.request("GET", "/domains/#{domain_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html
  end
end
