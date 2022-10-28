require "../../spec_helper"

describe "Http::Tags::Show" do
  it "shows DNE" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    req = HTTP::Request.new("GET", "/tags/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html

    req = user1.request("GET", "/tags/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html
  end

  it "shows active" do
    empty_db

    user1 = TestUser.new(handle: "username1")
    tag = Kpbb::Tag.save!(value: "example.com")

    req = HTTP::Request.new("GET", "/tags/#{tag.value}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html

    req = user1.request("GET", "/tags/#{tag.value}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "shows not active" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    tag = Kpbb::Tag.save!(value: "example.com", active: false)

    req = HTTP::Request.new("GET", "/tags/#{tag.value}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html

    req = user1.request("GET", "/tags/#{tag.value}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html
  end
end
