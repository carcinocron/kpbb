require "../../../../spec_helper"

describe "Http::Test::Raven::Handler::Route500" do
  it "shows 500 for guest" do
    empty_db

    req = HTTP::Request.new("GET", "/ravenhandlertest-route1-500?is_cool=1&def[a]=true&nice[]=one&nice[]=two", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 500
    res.should be_html

    req = HTTP::Request.new("GET", "/ravenhandlertest-route1-500?is_cool=1&def[a]=true&nice[]=one&nice[]=two", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_500
    # pp res
  end

  it "shows 500 for user" do
    empty_db
    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/ravenhandlertest-route1-500?is_cool=1&def[a]=true&nice[]=one&nice[]=two", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 500
    res.should be_html

    req = user1.request("GET", "/ravenhandlertest-route1-500?is_cool=1&def[a]=true&nice[]=one&nice[]=two", default_browser_get_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_500
    # pp res
  end
end
