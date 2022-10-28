require "../../../../spec_helper"

describe "Http::Test::Raven::Handler::Route404" do
  it "shows 404 for guest" do
    empty_db

    req = HTTP::Request.new("GET", "/ravenhandlertest-route404", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html

    req = HTTP::Request.new("GET", "/ravenhandlertest-route404", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_404
  end

  it "shows 404 for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/ravenhandlertest-route404", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html

    req = user1.request("GET", "/ravenhandlertest-route404", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_404
  end
end
