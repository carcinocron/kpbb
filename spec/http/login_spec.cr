require "../spec_helper"

describe "Http::Login" do

  it "rejects empty payload" do
    empty_db
    req = HTTP::Request.new("POST", "/login", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle required."],
      :password => ["Password required."],
    })

    assert_login_attempts success: 0, failed: 1
  end

  it "rejects missing user" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "username1"
      form.add "password", "password1"
    end
    req = HTTP::Request.new("POST", "/login", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Account not found."],
    })

    assert_login_attempts success: 0, failed: 1
  end

  it "rejects wrong password" do
    empty_db
    user = TestUser.new(handle: "username1")
    body = HTTP::Params.build do |form|
      form.add "handle", "username1"
      form.add "password", "random other password"
    end
    req = HTTP::Request.new("POST", "/login", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :password => ["Password did not match."],
    })
    assert_handle_session_user_id user.handle, nil
    assert_login_attempts success: 0, failed: 1
  end

  it "accepts valid login" do
    empty_db
    user = TestUser.new(handle: "username1")
    body = HTTP::Params.build do |form|
      form.add "handle", user.handle
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/login", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.status_code.should eq 200
    res.body.should eq ({
      "id" => user.id,
    }).to_json
    assert_handle_session_user_id user.handle, user.id
    assert_login_attempts success: 1, failed: 0
  end
end
