require "../../../spec_helper"

describe "Http::Settings::Profile::Update" do
  it "updates bio" do
    empty_db
    req = HTTP::Request.new("POST", "/settings/profile", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_401

    user1 = TestUser.new(handle: "username1")

    new_bio = "new bio value"
    req = user1.request("POST", "/settings/profile", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_ok

    get_user_prop_s(user1.id, "bio").should_not eq new_bio

    req = user1.request("POST", "/settings/profile", default_browser_post_headers.merge!(accepts_json), "bio=#{new_bio}")
    res = process_request req
    res.should be_json_200_ok

    get_user_prop_s(user1.id, "bio").should eq new_bio
  end

  it "updates profile prop pronouns" do
    empty_db
    user1 = TestUser.new(handle: "username1")

    new_value = "new pronouns value"

    req = user1.request("POST", "/settings/profile", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_ok

    get_user_prop_s(user1.id, "pronouns").not_nil!.should_not eq new_value

    req = user1.request("POST", "/settings/profile", default_browser_post_headers.merge!(accepts_json), "pronouns=#{new_value}")
    res = process_request req
    res.should be_json_422 ({
      :pronouns => ["Pronouns must be under 16 characters."],
    })

    new_value = "123456789012345"
    req = user1.request("POST", "/settings/profile", default_browser_post_headers.merge!(accepts_json), "pronouns=#{new_value}")
    res = process_request req
    res.should be_json_200_ok

    get_user_prop_s(user1.id, "pronouns").not_nil!.should eq new_value

    req = user1.request("POST", "/settings/profile", default_browser_post_headers.merge!(accepts_json), "pronouns=#{new_value}")
    res = process_request req
    res.should be_json_200_ok

    get_user_prop_s(user1.id, "pronouns").not_nil!.should eq new_value
  end

  it "updates profile prop dname" do
    empty_db
    user1 = TestUser.new(handle: "username1")

    new_value = "new dname value"

    req = user1.request("POST", "/settings/profile", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_ok

    get_user_prop_s(user1.id, "dname").not_nil!.should_not eq new_value

    req = user1.request("POST", "/settings/profile", default_browser_post_headers.merge!(accepts_json), "dname=#{new_value}")
    res = process_request req
    res.should be_json_200_ok

    get_user_prop_s(user1.id, "dname").should eq new_value

    req = user1.request("POST", "/settings/profile", default_browser_post_headers.merge!(accepts_json), "dname=#{new_value}")
    res = process_request req
    res.should be_json_200_ok

    get_user_prop_s(user1.id, "dname").should eq new_value
  end
end

private def get_user_prop_s(user_id : Int64, prop : String) : String?
  query = <<-SQL
  SELECT "#{prop}" FROM users WHERE id = $1
  SQL
  value = Kpbb.db.query_one query, args: [user_id], as: {String?}
  value
end
