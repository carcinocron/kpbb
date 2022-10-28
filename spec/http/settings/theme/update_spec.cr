require "../../../spec_helper"

describe "Http::Settings::Theme::Update" do
  it "update theme preferences" do
    empty_db
    req = HTTP::Request.new("POST", "/settings/theme", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_401

    user1 = TestUser.new(handle: "username1")
    original_theme_id = get_theme_id(user1.id)

    req = user1.request("POST", "/settings/theme", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_200_ok

    req = user1.request("POST", "/settings/theme", default_browser_post_headers.merge!(accepts_json), "theme_id=4400")
    res = process_request req
    res.should be_json_422 ({
      :theme_id => ["Invalid theme."],
    })

    new_theme_id = 2
    original_theme_id.should eq 0_u16
    original_theme_id.should_not eq new_theme_id

    req = user1.request("POST", "/settings/theme", default_browser_post_headers.merge!(accepts_json), "theme_id=#{new_theme_id}")
    res = process_request req
    res.should be_json_200_ok

    get_theme_id(user1.id).should eq new_theme_id
  end
end

private def get_theme_id(user_id : Int64) : Int16?
  theme_id = Kpbb.db.query_one <<-SQL,
  SELECT theme_id FROM users WHERE id = $1
  SQL
    args: [user_id], as: {Int16}
  theme_id
end
