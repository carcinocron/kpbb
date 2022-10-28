require "../../../spec_helper"

describe "Http::Settings::Password::Show" do
  it "shows page" do
    empty_db
    req = HTTP::Request.new("GET", "/settings/password", default_browser_post_headers, "")
    res = process_request req
    res.should be_redirect_login

    user1 = TestUser.new(handle: "username1")
    req = user1.request("GET", "/settings/password", default_browser_post_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
