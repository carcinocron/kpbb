require "../../spec_helper"

describe "Http::Loginattempts::Show" do
  it "shows login redirect for guest when DNE" do
    empty_db
    req = HTTP::Request.new("GET", "/loginattempts/50", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login
  end

  it "shows Forbidden for regular user when DNE" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    req = user1.request("GET", "/loginattempts/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html
  end

  it "shows 404 for admin when DNE" do
    empty_db
    user1 = TestUser.new(handle: "username1", rank: 1)
    req = user1.request("GET", "/loginattempts/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html
  end

  it "shows login redirect for guest" do
    empty_db
    loginattmpt_id = get_loginattmpt_id
    req = HTTP::Request.new("GET", "/loginattempts/#{loginattmpt_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login
  end

  it "shows 403 for regular user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    loginattmpt_id = get_loginattmpt_id
    req = user1.request("GET", "/loginattempts/#{loginattmpt_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html
  end

  it "shows for admin user" do
    empty_db
    user1 = TestUser.new(handle: "username1", rank: 1)
    loginattmpt_id = get_loginattmpt_id
    # @todo admin
    req = user1.request("GET", "/loginattempts/#{loginattmpt_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end

private def get_loginattmpt_id
  req = HTTP::Request.new("POST", "/login", default_browser_get_headers, "handle=username1&password=someinvalidpassword")
  res = process_request req
  loginattmptId : Int64 = Kpbb.db.query_one(<<-SQL,
    SELECT id FROM loginattempts ORDER BY id DESC LIMIT 1
  SQL
    as: Int64)
  loginattmptId
end
