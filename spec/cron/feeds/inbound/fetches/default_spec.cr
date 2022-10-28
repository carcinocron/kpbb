require "../../../../spec_helper"

describe "Cron::Feeds::Inbound::Fetches::Default" do
  it "feed1.xml" do
    empty_db
    user = TestUser.new(handle: "username1")
    channel1 = Kpbb::Channel.factory(creator_id: user.id)
    endpoint1 = Kpbb::Feed::Inbound::Endpoint.factory(
      creator_id: user.id, channel_id: channel1.id,
      lastpolled_at: nil,
      url: "#{ENV["FN_MOCK_SERVE"]}/feed1.xml")

    minute = Time.utc

    (endpoints = Kpbb::Feed::Inbound::Endpoint.all).size.should eq 1
    endpoint_before_poll = endpoints[0]
    # p "<endpoint_before_poll>"
    # pp endpoint_before_poll
    # p "</endpoint_before_poll>"
    endpoint_before_poll.data_s.should be_nil
    endpoint_before_poll.lastpolled_at.should be_nil
    endpoint_before_poll.nextpoll_at.should be_nil
    endpoint_before_poll.updated_at.should be_truthy

    Kpbb::Cron::Feed::Inbound::Endpoint::Fetch.run minute

    (endpoints = Kpbb::Feed::Inbound::Endpoint.all).size.should eq 1
    (payloads = Kpbb::Feed::Inbound::Payload.all).size.should eq 10

    (endpoints = Kpbb::Feed::Inbound::Endpoint.all).size.should eq 1
    endpoint_after_poll = endpoints[0]
    # p "<endpoint_after_poll>"
    # pp endpoint_after_poll
    # p "</endpoint_after_poll>"
    endpoint_after_poll.data_s.should be_truthy
    endpoint_after_poll.lastpolled_at.should be_truthy
    endpoint_after_poll.nextpoll_at.should be_truthy
    endpoint_after_poll.updated_at.should be > endpoint_before_poll.updated_at

    payload_0_before_run = payloads[0]
    # p "<payload_0_before_run>"
    # pp payload_0_before_run
    # p "</payload_0_before_run>"
    payload_0_before_run.data_s.should be_truthy
    payload_0_before_run.result_s.should be_nil
    payload_0_before_run.updated_at.should be_truthy

    payload_9_before_run = payloads[9]
    # p "<payload_9_before_run>"
    # pp payload_9_before_run
    # p "</payload_9_before_run>"
    payload_9_before_run.data.should be_truthy
    payload_9_before_run.result_s.should be_nil
    payload_9_before_run.updated_at.should be_truthy

    Kpbb::Cron::Feed::Inbound::Payload::Fetch.run minute

    (endpoints = Kpbb::Feed::Inbound::Endpoint.all).size.should eq 1
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
    post.published_at.should be_nil
    post.draft.should be_true
    post.ptype.should eq Kpbb::Post::Type::None

    # payload_9_after_run = payloads[9]
    # p "<payload_9_after_run>"
    # # pp payload_9_after_run
    # pp payload_9_after_run.result
    # p "</payload_9_after_run>"

    # pp ({:payload_results => payloads.map(&.result)})

    Kpbb::Cron::Feed::Inbound::Payload::Fetch.run minute

    # (endpoints = Kpbb::Feed::Inbound::Endpoint.all).size.should eq 1
    (payloads = Kpbb::Feed::Inbound::Payload.all).size.should eq 10

    payload_1_after_run = payloads[1]
    # p "<payload_1_after_run>"
    # pp payload_1_after_run
    # p "</payload_1_after_run>"

    payload_1_after_run.result_s.should be_nil

    # pretend the last payload was made further in the past
    Kpbb.db.exec <<-SQL
      UPDATE feed_inbound_endpoints
      SET nextpost_at = NOW(),
        lastposted_at = NOW() - INTERVAL '10 minute'
    SQL

    Kpbb::Cron::Feed::Inbound::Payload::Fetch.run minute

    # (endpoints = Kpbb::Feed::Inbound::Endpoint.all).size.should eq 1
    (payloads = Kpbb::Feed::Inbound::Payload.all).size.should eq 10

    payload_1_after_run = payloads[1]

    payload_1_after_run.result_s.should eq ({:post_id => 1001}).to_json

    post = Kpbb::Post.find! 1001
    # pp post.url
    post.url.should eq "https://crystal-lang.org/2020/08/20/preparing-our-shards-for-crystal-1.0.html"
    post.title.should eq "Preparing our shards for Crystal 1.0"
    post.published_at.should be_nil
    post.draft.should be_true
    post.ptype.should eq Kpbb::Post::Type::None

    # pp ({:payload_results => payloads.map(&.result)})
  end
end
