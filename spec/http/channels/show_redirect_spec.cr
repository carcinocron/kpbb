require "../../spec_helper"

describe "Http::Channels::ShowRedirect" do
  it "redirects shorthand /c/:handle to /channels/:handle" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id)
    req = HTTP::Request.new("GET", "/c/#{channel.id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 302
    res.body.should eq ""
    res.headers["Location"]?.should eq "/channels/#{channel.id.to_b62}"
    res.headers["Content-Type"]?.should eq "text/html; charset=utf-8"
  end
end
