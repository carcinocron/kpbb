require "../../../../spec_helper"

describe "Http::Posts::Webhook::Inbound::Endpoint::Create" do
  it "accepts empty payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user.id)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    form = HTTP::Params.build do |form|
      form.add "secret", plaintext_password()
    end
    req = HTTP::Request.new("POST", "/webhook/#{endpoint.uuid.to_base62}/posts", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    res.status_code.should eq 200
    (payloads = Kpbb::Webhook::Inbound::Payload.all).size.should eq 1
    payloads[0].data_s.should eq ({
      :body => ({
        :dedupe_minutes => "10080",
      }),
      :creator_id => user.id,
    }).to_json
  end

  it "accepts valid payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user.id)
    endpoint1 = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    endpoint2 = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id, active: false)
    form = HTTP::Params.build do |form|
      form.add "secret", plaintext_password()
      form.add "title", "nice"
    end
    req = HTTP::Request.new("POST", "/webhook/#{endpoint1.uuid.to_base62}/posts", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    res.status_code.should eq 200
    (payloads = Kpbb::Webhook::Inbound::Payload.all).size.should eq 1
    payloads[0].data_s.should eq ({
      :body => {
        :title          => "nice",
        :dedupe_minutes => "10080",
      },
      :creator_id => user.id,
    }).to_json

    req = HTTP::Request.new("POST", "/webhook/#{endpoint2.uuid.to_base62}/posts", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    res.should be_json_404
  end

  it "rejects invalid webhook call" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(creator_id: user.id)
    endpoint = Kpbb::Webhook::Inbound::Endpoint.factory(creator_id: user.id, channel_id: channel.id)
    form = HTTP::Params.build do |form|
      form.add "secret", plaintext_password()
    end

    # shorter than UUID
    req = HTTP::Request.new("POST", "/webhook/1234567890/posts", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    be_json_404

    # longer than UUID
    req = HTTP::Request.new("POST", "/webhook/#{endpoint.uuid.to_base62}0/posts", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    be_json_404

    # invalid uuid (-= are not base62)
    req = HTTP::Request.new("POST", "/webhook/123456789-01234567890=1234567890/posts", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    be_json_404

    # dne uuid
    req = HTTP::Request.new("POST", "/webhook/#{UUID.random.to_s.gsub("-", "")}/posts", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    be_json_404

    # missing secret
    req = HTTP::Request.new("POST", "/webhook/#{endpoint.uuid.to_base62}/posts", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    be_json_404

    # invalid path
    req = HTTP::Request.new("POST", "/webhook/#{endpoint.uuid.to_base62}/billy", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    be_json_404

    # no path 1
    req = HTTP::Request.new("POST", "/webhook/#{endpoint.uuid.to_base62}", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    be_json_404

    # no path 2
    req = HTTP::Request.new("POST", "/webhook/#{endpoint.uuid.to_base62}/", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    be_json_404

    # wrong secret
    form = HTTP::Params.build do |form|
      form.add "secret", plaintext_password() + "2"
    end
    req = HTTP::Request.new("POST", "/webhook/#{endpoint.uuid.to_base62}/posts", default_browser_post_headers.merge!(accepts_json), form)
    res = process_request req
    be_json_404

    (Kpbb::Webhook::Inbound::Payload.all).size.should eq 0
  end
end
