require "../../spec_helper"

describe "Http::Users::ShowRedirect" do
  it "redirects shorthand /u/:handle to /users/:handle" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    req = HTTP::Request.new("GET", "/u/#{user1.id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 302
    res.body.should eq ""
    res.headers["Location"]?.should eq "/users/#{user1.id.to_b62}"
    res.headers["Content-Type"]?.should eq "text/html; charset=utf-8"
  end
end
