require "../spec_helper"
require "../../src/markdown"

describe "Twitter::String::IsTweetUrl" do
  it "returns true for valid tweets" do
    meta = Kpbb::Twitter.tweet_url_meta("https://twitter.com/someone/status/866002913604149248")
    meta.should be_truthy
    meta.try(&.handle).should eq "someone"
    meta.try(&.tweet_id).should eq "866002913604149248"
    Kpbb::Twitter.tweet_url_meta("https://twitter.com/someone/status/857179125076963329/video/1").should be_truthy
    Kpbb::Twitter.tweet_url_meta("https://twitter.com/someone/status/857179125076963329/video/1/").should be_truthy
    Kpbb::Twitter.tweet_url_meta("https://twitter.com/someone/status/866002913604149248/").should be_truthy
  end

  it "returns false for not https" do
    Kpbb::Twitter.tweet_url_meta("http://twitter.com/someone/status/866002913604149248").should be_nil
    Kpbb::Twitter.tweet_url_meta("//twitter.com/someone/status/866002913604149248").should be_nil
    Kpbb::Twitter.tweet_url_meta("/twitter.com/someone/status/866002913604149248").should be_nil
  end

  it "returns false for strings that are not tweets" do
    Kpbb::Twitter.tweet_url_meta("https://example.com/someone/status/866002913604149248").should be_nil
    Kpbb::Twitter.tweet_url_meta("https://example.com/someone/status/857179125076963329/video/1").should be_nil
    Kpbb::Twitter.tweet_url_meta("https://twitter.com/someone/status/").should be_nil
    Kpbb::Twitter.tweet_url_meta("https://twitter.com/someone/status").should be_nil
    Kpbb::Twitter.tweet_url_meta("https://twitter.com/someone/").should be_nil
    Kpbb::Twitter.tweet_url_meta("https://twitter.com/someone").should be_nil
    Kpbb::Twitter.tweet_url_meta("https://twitter.com/").should be_nil
    Kpbb::Twitter.tweet_url_meta("https://twitter.com").should be_nil
  end
end
