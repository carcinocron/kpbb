require "../../../../spec_helper"

describe "Cron::Feeds::Inbound::Fetches::Autopublish" do
  it "will autopublish when body.draft=false" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel1 = Kpbb::Channel.factory(creator_id: user.id)
    endpoint1 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel1.id,
      lastpolled_at: nil,
      default_body: ({
        :draft => "0",
      }).to_json,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed1.xml")

    minute = Time.utc

    (endpoints = Kpbb::Feed::Inbound::Endpoint.all).size.should eq 1

    Kpbb::Cron::Feed::Inbound::Endpoint::Fetch.run minute

    (payloads = Kpbb::Feed::Inbound::Payload.all).size.should eq 10

    Kpbb::Cron::Feed::Inbound::Payload::Fetch.run minute
    (payloads = Kpbb::Feed::Inbound::Payload.all).size.should eq 10

    payload_0_after_run = payloads[0]
    # p "<payload_0_after_run>"
    # pp payload_0_after_run
    # p "</payload_0_after_run>"

    payload_0_after_run.result_s.should eq ({:post_id => 1000}).to_json

    post = Kpbb::Post.find! 1000
    # pp post.url
    post.url.should eq "https://crystal-lang.org/2020/08/24/announcing-new-apt-and-rpm-repositories.html"
    post.title.should eq "Announcing new apt and rpm repositories"
    post.draft.should be_false
    post.published_at.should be_truthy
    post.ptype.should eq Kpbb::Post::Type::None
  end
end
