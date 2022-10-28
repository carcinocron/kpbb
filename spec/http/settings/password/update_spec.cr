require "../../../spec_helper"

describe "Http::Settings::Password::Update" do
  it "update password" do
    empty_db
    req = HTTP::Request.new("POST", "/settings/password", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_401

    user1 = TestUser.new(handle: "username1")

    req = user1.request("POST", "/settings/password", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_422 ({
      :current_password => ["Current password required."],
      :password         => ["Password required."],
    })

    req = user1.request("POST", "/settings/password", default_browser_post_headers.merge!(accepts_json), "current_password=a&password=#{plaintext_password}2")
    res = process_request req
    res.should be_json_422 ({
      :current_password => ["Current password must be at least 8 characters."],
    })

    req = user1.request("POST", "/settings/password", default_browser_post_headers.merge!(accepts_json), "current_password=#{plaintext_password}&password=a")
    res = process_request req
    res.should be_json_422 ({
      :password => ["Password must be at least 8 characters."],
    })

    req = user1.request("POST", "/settings/password", default_browser_post_headers.merge!(accepts_json), "current_password=#{plaintext_password}2&password=#{plaintext_password}2")
    res = process_request req
    res.should be_json_422 ({
      :current_password => ["Current password must be different from new password."],
    })

    get_hashed_password(user1.id).should eq hashed_password()

    req = user1.request("POST", "/settings/password", default_browser_post_headers.merge!(accepts_json), "current_password=#{plaintext_password}3&password=#{plaintext_password}2")
    res = process_request req
    res.should be_json_422 ({
      :current_password => ["Current password did not match."],
    })

    new_password = "#{plaintext_password}2"
    req = user1.request("POST", "/settings/password", default_browser_post_headers.merge!(accepts_json), "current_password=#{plaintext_password}&password=#{new_password}")
    res = process_request req
    res.should be_json_200_ok

    get_hashed_password(user1.id).should_not eq hashed_password()
  end
end

private def get_hashed_password(id) : String?
  hashed_password = Kpbb.db.query_one <<-SQL,
  SELECT hash as password FROM users
  LEFT JOIN passwords ON passwords.id = users.pw_id
  WHERE users.id = $1
  SQL
    args: [id], as: {String?}
  hashed_password
end
