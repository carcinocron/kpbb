require "../../spec_helper"

describe "Http::Channels::Create" do
  it "rejects empty payload" do
    empty_db
    user = TestUser.new(handle: "username1")
    req = user.request("POST", "/channels", default_browser_post_headers.merge!(accepts_json), "")
    res = process_request req
    res.should be_json_422 ({
      :handle => ["Handle required."],
      # :dname => ["Name required."], #dname will default to handle
      # :bio => ["Description required."],
    })
  end

  # it "rejects short name" do
  #   empty_db
  #   user = TestUser.new(handle: "username1")
  #   form = HTTP::Params.build do |form|
  #     form.add "handle", "channel1"
  #     form.add "dname", "ab"
  #     form.add "bio", ""
  #   end
  #   req = user.request("POST", "/channels", default_browser_post_headers.merge!(accepts_json), form.to_s)
  #   res = process_request req
  #   res.should be_json_422 ({
  #     :dname => ["Name must be between 3 and 32 characters."],
  #   })
  # end

  it "rejects long name" do
    empty_db
    user = TestUser.new(handle: "username1")
    form = HTTP::Params.build do |form|
      form.add "handle", "channel1"
      form.add "dname", "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
      form.add "bio", ""
    end
    req = user.request("POST", "/channels", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_422 ({
      :dname => ["Display Name must be under 48 characters."],
    })
  end

  it "accepts valid data" do
    empty_db
    user = TestUser.new(handle: "username1")
    form = HTTP::Params.build do |form|
      form.add "handle", "channel1"
      form.add "dname", "channel1"
      form.add "bio", ""
    end
    req = user.request("POST", "/channels", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    channel = Kpbb::Channel.find! get_id(res)
    # default values
    channel.public.should eq false
    channel.listed.should eq false
    channel.dname.should eq "channel1"
    channel.bio.should eq ""
    Kpbb::ChannelMembership.find!(channel.id, user.id)
  end

  it "accepts optional boolean value false" do
    empty_db
    user = TestUser.new(handle: "username1")
    form = HTTP::Params.build do |form|
      form.add "handle", "channel1"
      form.add "dname", "channel1"
      form.add "bio", ""
      form.add "public", "false"
      form.add "listed", "false"
    end
    req = user.request("POST", "/channels", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    channel = Kpbb::Channel.find! get_id(res)
    channel.public.should eq false
    channel.listed.should eq false
  end

  it "accepts optional boolean value true" do
    empty_db
    user = TestUser.new(handle: "username1")
    form = HTTP::Params.build do |form|
      form.add "handle", "channel1"
      form.add "dname", "channel1"
      form.add "bio", ""
      form.add "public", "true"
      form.add "listed", "true"
    end
    req = user.request("POST", "/channels", default_browser_post_headers.merge!(accepts_json), form.to_s)
    res = process_request req
    res.should be_json_200_just_id
    channel = Kpbb::Channel.find! get_id(res)
    channel.public.should eq true
    channel.listed.should eq true
  end
end
