require "../../spec_helper"

describe "Http::Invitecode::Register" do
  it "rejects when invitecode is required" do
    empty_db
    Kpbb.db.exec <<-SQL
      INSERT INTO appsettingskv (k, v)
      VALUES ('register_require_invitecode', '1')
    SQL
    body = HTTP::Params.build do |form|
      form.add "handle", "Username1"
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :invitecode => ["Invite code required."],
    })
  end

  it "rejects when invitecode is wrong (different code)" do
    empty_db
    user = TestUser.new(handle: "username1")
    invitecode = TestInvitecode.new(inviter_id: user.id, code: "code1")
    body = HTTP::Params.build do |form|
      form.add "handle", "handle2"
      form.add "password", plaintext_password
      form.add "invitecode", invitecode.code + "b"
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :invitecode => ["Invite code invalid."],
    })
    freshinvitecode = TestInvitecode.new(invitecode.id)
    freshinvitecode.redeemer_id.should be_nil
    freshinvitecode.redeemed_at.should be_nil
  end

  it "rejects when invitecode is wrong (first letter uppercased)" do
    empty_db
    user = TestUser.new(handle: "username1")
    invitecode = TestInvitecode.new(inviter_id: user.id, code: "code1")
    body = HTTP::Params.build do |form|
      form.add "handle", "handle2"
      form.add "password", plaintext_password
      form.add "invitecode", "Code1"
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :invitecode => ["Invite code invalid."],
    })
  end

  it "accepts valid register when invitecode is not required" do
    empty_db
    user = TestUser.new(handle: "handle1")
    invitecode = TestInvitecode.new(inviter_id: user.id, code: "code1")
    body = HTTP::Params.build do |form|
      form.add "handle", "handle2"
      form.add "password", plaintext_password
      form.add "invitecode", invitecode.code
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_200_just_id
    user = TestUser.new get_id(res)
    # assert session exists
    assert_handle_session_user_id "handle2", user.id

    freshinvitecode = TestInvitecode.new(invitecode.id)
    freshinvitecode.redeemer_id.should eq user.id
    freshinvitecode.redeemed_at.should be_truthy

    # @todo notification
  end

  it "accepts valid register when invitecode is required" do
    empty_db
    Kpbb.db.exec <<-SQL
      INSERT INTO appsettingskv (k, v)
      VALUES ('register_require_invitecode', '1')
    SQL
    user = TestUser.new(handle: "handle1")
    invitecode = TestInvitecode.new(inviter_id: user.id, code: "code1")
    body = HTTP::Params.build do |form|
      form.add "handle", "handle2"
      form.add "password", plaintext_password
      form.add "invitecode", invitecode.code
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_200_just_id
    user = TestUser.new get_id(res)
    # assert session exists
    assert_handle_session_user_id "handle2", user.id

    freshinvitecode = TestInvitecode.new(invitecode.id)
    freshinvitecode.redeemer_id.should eq user.id
    freshinvitecode.redeemed_at.should be_truthy
  end

  it "accepts valid register when invitecode has trailing space" do
    empty_db
    user = TestUser.new(handle: "handle1")
    invitecode = TestInvitecode.new(inviter_id: user.id, code: "code1")
    body = HTTP::Params.build do |form|
      form.add "handle", "handle2"
      form.add "password", plaintext_password
      form.add "invitecode", invitecode.code + " "
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_200_just_id
    user = TestUser.new get_id(res)
    # assert session exists
    assert_handle_session_user_id "handle2", user.id

    freshinvitecode = TestInvitecode.new(invitecode.id)
    freshinvitecode.redeemer_id.should eq user.id
    freshinvitecode.redeemed_at.should be_truthy
  end

  it "renders HTML when invitecode is required" do
    empty_db
    Kpbb.db.exec <<-SQL
      INSERT INTO appsettingskv (k, v)
      VALUES ('register_require_invitecode', '1')
    SQL
    req = HTTP::Request.new("GET", "/register", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end
end
