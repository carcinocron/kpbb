require "../../spec_helper"

describe "Http::Loginattempts::List" do
  it "lists redirect to login for guest" do
    empty_db
    req = HTTP::Request.new("GET", "/loginattempts", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login
  end

  it "lists 403 for regular user" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    loginattempt_id = get_loginattempt_id
    req = user1.request("GET", "/loginattempts", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html
  end

  it "lists for admin user" do
    empty_db
    user1 = TestUser.new(handle: "username1", rank: 1)
    loginattempt_id = get_loginattempt_id
    # @todo admin
    req = user1.request("GET", "/loginattempts", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end

private def get_loginattempt_id
  req = HTTP::Request.new("POST", "/login", default_browser_get_headers, "handle=username1&password=someinvalidpassword")
  res = process_request req
  loginattemptId : Int64 = Kpbb.db.query_one(<<-SQL,
    SELECT id FROM loginattempts ORDER BY id DESC LIMIT 1
  SQL
    as: Int64)
  loginattemptId
end
