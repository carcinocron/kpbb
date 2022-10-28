require "../../../spec_helper"

describe "Http::Settings::Email::Update" do
  it "rejects invalid add email" do
    empty_db

    # guest
    req = HTTP::Request.new("POST", "/settings/email", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_401
    (emails = Kpbb::Email.all).size.should eq 0

    user1 = TestUser.new(handle: "username1")

    # empty (undefined)
    req = user1.request("POST", "/settings/email", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_422 ({
      add_email: ["The Email address is too short."],
    })
    (emails = Kpbb::Email.all).size.should eq 0

    # empty (empty string)
    req = user1.request("POST", "/settings/email", default_browser_post_headers.merge!(accepts_json), "add_email=")
    res = process_request req
    res.should be_json_422 ({
      add_email: ["The Email address is too short."],
    })
    (emails = Kpbb::Email.all).size.should eq 0

    # missing @
    new_value = "billy2example.com"
    req = user1.request("POST", "/settings/email", default_browser_post_headers.merge!(accepts_json), "add_email=#{new_value}")
    res = process_request req
    res.should be_json_422 ({
      add_email: ["The Email address is invalid."],
    })
    (emails = Kpbb::Email.all).size.should eq 0

    # missing .
    new_value = "billy@examplecom"
    req = user1.request("POST", "/settings/email", default_browser_post_headers.merge!(accepts_json), "add_email=#{new_value}")
    res = process_request req
    res.should be_json_422 ({
      add_email: ["The Email address is invalid."],
    })
    (emails = Kpbb::Email.all).size.should eq 0

    # missing . after @
    new_value = "billy.shrek@examplecom"
    req = user1.request("POST", "/settings/email", default_browser_post_headers.merge!(accepts_json), "add_email=#{new_value}")
    res = process_request req
    res.should be_json_422 ({
      add_email: ["The Email address is invalid."],
    })
    (emails = Kpbb::Email.all).size.should eq 0

    # valid
    new_value = "billy@example.com"
    req = user1.request("POST", "/settings/email", default_browser_post_headers.merge!(accepts_json), "add_email=#{new_value}")
    res = process_request req
    res.should be_json_200_ok
    (emails = Kpbb::Email.all).size.should eq 1

    emails[0].email.should eq new_value
    emails[0].verified.should be_false
    emails[0].recovery.should be_false

    # valid + recovery
    new_value = "billy2@example.com"
    req = user1.request("POST", "/settings/email", default_browser_post_headers.merge!(accepts_json), "add_email=#{new_value}&add_recovery=1")
    res = process_request req
    res.should be_json_200_ok
    (emails = Kpbb::Email.all).size.should eq 2

    emails[1].email.should eq new_value
    emails[1].verified.should be_false
    emails[1].recovery.should be_true
  end
end
