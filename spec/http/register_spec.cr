require "../spec_helper"

describe "Http::Register" do
  it "rejects empty payload" do
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_422 ({
      :handle   => ["Handle required."],
      :password => ["Password required."],
    })
  end

  it "rejects empty password" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "username1"
      form.add "password", ""
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :password => ["Password required."],
    })
    assert_handle_session_user_id "username1", nil
  end

  it "rejects short password" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "username1"
      form.add "password", "abc1"
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :password => ["Password must be at least 8 characters."],
    })
    assert_handle_session_user_id "username1", nil
  end

  it "rejects empty handle" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", ""
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle required."],
    })
    assert_handle_session_user_id "username1", nil
  end

  it "rejects short handle" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "ab"
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle must be between 3 and 32 characters."],
    })
    assert_handle_session_user_id "username1", nil
  end

  it "rejects long handle" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "abcdefghijklmnopqrstuvwxyz0123456"
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle must be between 3 and 32 characters."],
    })
    assert_handle_session_user_id "username1", nil
  end

  it "rejects handle starts with number" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "4abcdefghijklmn"
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle must start with a letter."],
    })
    assert_handle_session_user_id "username1", nil
  end

  it "rejects handle starts with dash" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "-abcdefghijklmn"
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle must start with a letter."],
    })
    assert_handle_session_user_id "username1", nil
  end

  it "rejects handle abuses dashes 1" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "abcd--efghijklmn"
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle must not abuse dashes and underscores."],
    })
    assert_handle_session_user_id "username1", nil
  end

  it "rejects handle ends with dash" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "abcdefghijklmn-"
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle must end with a letter or number."],
    })
    assert_handle_session_user_id "username1", nil
  end

  it "rejects unmatched password2" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "handle1"
      form.add "password", plaintext_password
      form.add "password2", plaintext_password + "a"
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :password2 => ["Password does not match."],
    })
    assert_handle_session_user_id "username1", nil
  end

  it "rejects empty, but present, unmatched password2" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "handle1"
      form.add "password", plaintext_password
      form.add "password2", ""
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :password2 => ["Password does not match."],
    })
    assert_handle_session_user_id "username1", nil
  end

  it "accepts valid register" do
    empty_db
    body = HTTP::Params.build do |form|
      form.add "handle", "handle1"
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_200_just_id
    user = TestUser.new get_id(res)
    # assert session exists
    assert_handle_session_user_id "handle1", user.id

    emails = Kpbb::Email.all
    emails.size.should eq 0
  end

  it "rejects existing user" do
    empty_db
    user = TestUser.new(handle: "username1")
    body = HTTP::Params.build do |form|
      form.add "handle", "username1"
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle already taken."],
    })
  end

  it "rejects same handle when case different" do
    empty_db
    user = TestUser.new(handle: "username1")
    body = HTTP::Params.build do |form|
      form.add "handle", "Username1"
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle already taken."],
    })
  end

  it "renders HTML" do
    empty_db
    req = HTTP::Request.new("GET", "/register", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html
  end

  it "accepts optional email" do
    empty_db
    email_address = "billy@example.com"
    body = HTTP::Params.build do |form|
      form.add "handle", "handle1"
      form.add "password", plaintext_password
      form.add "email", email_address
    end
    req = HTTP::Request.new("POST", "/register", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    res.should be_json_200_just_id
    user = TestUser.new get_id(res)
    # assert session exists
    assert_handle_session_user_id "handle1", user.id

    emails = Kpbb::Email.all
    emails = Kpbb::Email.find(user_id: user.id, email: email_address)
    emails.size.should eq 1
    # pp emails[0]
    # pp emails[0].data.to_encrypted
    # pp Kpbb::Email::Data.from_encrypted (emails[0].data.to_encrypted)
    emails[0].email.should eq email_address
    emails[0].active.should be_true
    emails[0].verified.should be_false
  end
end
