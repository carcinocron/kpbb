require "../../../../spec_helper"

describe "Http::Webhook::Cron::ChannelJob::PublishPost" do
  it "webhook cron publishes post" do
    empty_db
    now = Time.utc.at_beginning_of_minute
    in_5_min = now.at_beginning_of_minute + 5.minutes
    user = TestUser.new
    channel = Kpbb::Channel.factory(creator_id: user.id)
    post = Kpbb::Post.factory(draft: true, published_at: Time.local, channel_id: channel.id, creator_id: user.id)
    channeljob = TestChannelJob.new(user_id: user.id,
      channel_id: channel.id, post_id: post.id,
      action: Kpbb::ChannelAction::Publish,
      run_at: in_5_min)

    TestChannelJob.all.size.should eq 1
    Kpbb::ChannelJob.all_for_minute(now).size.should eq 0
    Kpbb::ChannelJob.all_for_minute(in_5_min).size.should eq 1

    Kpbb::Cron::ChannelJob.run minute: now

    TestChannelJob.all.size.should eq 1
    TestChannelLog.all.size.should eq 0

    # run cron at scheduled time, expect action
    Kpbb::Cron::ChannelJob.run minute: in_5_min

    TestChannelJob.all.size.should eq 0
    (channellogs = TestChannelLog.all).size.should eq 1
    channellogs[0].action.should eq channeljob.action
    channellogs[0].data.should be_truthy
    channel_job_result : Kpbb::ChannelLogData = Kpbb::ChannelLogData.from_json(channellogs[0].data.not_nil!)
    channel_job_result.job.should be_truthy
    freshchannel_job : Kpbb::ChannelJob = channel_job_result.job.not_nil!
    freshchannel_job.id.should eq channeljob.id
    channel_job_result.rows_affected.should eq 1
  end

  # it "accepts schedule_publish_at when valid value" do
  #   empty_db
  #   user = TestUser.new
  #   channel = Kpbb::Channel.factory(creator_id: user.id)
  #   post = Kpbb::Post.factory(draft: false, published_at: Time.local, channel_id: channel.id, creator_id: user.id)
  #   in_30_min = (Time.utc + 30.minutes)
  #   form = HTTP::Params.build do |form|
  #     form.add "title", "cool new post"
  #     form.add "channel_id", channel.id.to_b62
  #     form.add "draft", "1"
  #     form.add "schedule_publish_at", "@#{in_30_min.to_unix}"
  #   end
  #   req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
  #   res = process_request req
  #   res.should be_json_200_ok

  #   freshpost = Kpbb::Post.find!(post.id)
  #   freshpost.id.should eq post.id

  #   freshpost.posted.should eq true
  #   freshpost.draft.should eq true
  #   freshpost.published_at.should eq nil

  #   (channel_jobs = TestChannelJob.all).size.should eq 1
  #   channel_jobs[0].id.should be > 0
  #   channel_jobs[0].user_id.should eq user.id
  #   channel_jobs[0].post_id.should eq post.id
  #   channel_jobs[0].channel_id.should eq post.channel_id
  #   channel_jobs[0].comment_id.should be_nil
  #   channel_jobs[0].data.should be_nil
  #   channel_jobs[0].action.should eq Kpbb::ChannelAction::Publish
  #   channel_jobs[0].run_at.should be_close in_30_min, 1.second
  #   channel_jobs[0].run_at.should be > channel_jobs[0].created_at
  # end

  # it "rejects schedule_publish_at when invalid value" do
  #   empty_db
  #   user = TestUser.new
  #   channel = Kpbb::Channel.factory(creator_id: user.id)
  #   post = Kpbb::Post.factory(draft: false, published_at: Time.local, channel_id: channel.id, creator_id: user.id)
  #   form = HTTP::Params.build do |form|
  #     form.add "draft", "1"
  #     form.add "schedule_publish_at", "bojangles"
  #   end
  #   req = user.request("POST", "#{post.relative_url}", default_browser_post_headers.merge!(accepts_json), form.to_s)
  #   res = process_request req
  #   res.should be_json_422 ({
  #     :schedule_publish_at => ["Schedule publish post at timestamp could not be interpreted."],
  #   })

  #   TestChannelJob.all.size.should eq 0
  # end
end
