require "../spec_helper"

@[AlwaysInline]
private def fn(input)
  Iom::UrlAbbr.url_abbr(input)
end

describe "UrlAbbr" do
  it "makes expected outputs" do
    fn("https://www.example.com/").should eq "example.com"
    fn("https://example.com/").should eq "example.com"
    fn("http://example.com/").should eq "example.com"
    fn("http://example.com/friend-ship///").should eq "example.com"
    fn("http://example.com/friend-ship/nice/").should eq "example.com"
    fn("http://example.com/friend-ship/nice/yay/").should eq "example.com"
    fn("http://example.com/friend-ship/nice/yay#nope").should eq "example.com"
    fn("http://example.com:80/friend-ship").should eq "example.com"
    fn("ftp://example.com/friend-ship").should eq "example.com"
  end

  it "handles medium" do
    fn("https://www.medium.com/username/really-cool-article#literal-garbage").should eq "medium.com/username"
    fn("https://www.medium.com/username/really-cool-article?exactlocationofyourhome=9875349543").should eq "medium.com/username"
    fn("https://www.medium.com/username/really-cool-article").should eq "medium.com/username"
    fn("https://www.medium.com/username/").should eq "medium.com/username"
    fn("https://www.medium.com/username").should eq "medium.com/username"
  end

  it "handles twitter" do
    fn("https://twitter.com/username/status/12345").should eq "twitter.com/username"
    fn("https://www.twitter.com/username/status/12345").should eq "twitter.com/username"
    fn("https://www.twitter.com/username/").should eq "twitter.com/username"
    fn("https://www.twitter.com/username").should eq "twitter.com/username"
  end

  it "handles github" do
    fn("https://www.github.com/username/really-cool-repo/but-wait-theres-more").should eq "github.com/username/really-cool-repo"
    fn("https://www.github.com/username/really-cool-repo#literally-garbage").should eq "github.com/username/really-cool-repo"
    fn("https://www.github.com/username/really-cool-repo").should eq "github.com/username/really-cool-repo"
    fn("https://www.github.com/username/").should eq "github.com/username"
    fn("https://www.github.com/username").should eq "github.com/username"
  end

  it "handles gitlab" do
    fn("https://www.gitlab.com/username/really-cool-repo/but-wait-theres-more").should eq "gitlab.com/username/really-cool-repo"
    fn("https://www.gitlab.com/username/really-cool-repo#literally-garbage").should eq "gitlab.com/username/really-cool-repo"
    fn("https://www.gitlab.com/username/really-cool-repo").should eq "gitlab.com/username/really-cool-repo"
    fn("https://www.gitlab.com/username/").should eq "gitlab.com/username"
    fn("https://www.gitlab.com/username").should eq "gitlab.com/username"
  end

  it "handles reddit" do
    fn("https://www.reddit.com/r/subreddit/really-cool-repo/but-wait-theres-more").should eq "reddit.com/r/subreddit"
    fn("https://www.reddit.com/r/subreddit/really-cool-repo#literally-garbage").should eq "reddit.com/r/subreddit"
    fn("https://www.reddit.com/r/subreddit/really-cool-repo").should eq "reddit.com/r/subreddit"
    fn("https://www.reddit.com/r/subreddit/").should eq "reddit.com/r/subreddit"
    fn("https://www.reddit.com/r/subreddit").should eq "reddit.com/r/subreddit"
    fn("https://www.reddit.com/user/username/really-cool-repo/but-wait-theres-more").should eq "reddit.com/u/username"
    fn("https://www.reddit.com/user/username/really-cool-repo#literally-garbage").should eq "reddit.com/u/username"
    fn("https://www.reddit.com/user/username/really-cool-repo").should eq "reddit.com/u/username"
    fn("https://www.reddit.com/user/username/").should eq "reddit.com/u/username"
    fn("https://www.reddit.com/user/username").should eq "reddit.com/u/username"
    fn("https://www.reddit.com/gallery/abcde").should eq "reddit.com/gallery"
    fn("https://www.reddit.com/somerandom").should eq "reddit.com"
  end

  it "handles imgur" do
    # fn("https://www.imgur.com/r/subimgur/really-cool-repo/but-wait-theres-more").should eq "imgur.com/r/subimgur"
    # fn("https://www.imgur.com/r/subimgur/really-cool-repo#literally-garbage").should eq "imgur.com/r/subimgur"
    # fn("https://www.imgur.com/r/subimgur/really-cool-repo").should eq "imgur.com/r/subimgur"
    # fn("https://www.imgur.com/r/subimgur/").should eq "imgur.com/r/subimgur"
    # fn("https://www.imgur.com/r/subimgur").should eq "imgur.com/r/subimgur"
    fn("https://www.imgur.com/a/ABCDEFG123/really-cool-repo/but-wait-theres-more").should eq "imgur.com/a"
    fn("https://www.imgur.com/a/ABCDEFG123/really-cool-repo#literally-garbage").should eq "imgur.com/a"
    fn("https://www.imgur.com/a/ABCDEFG123/really-cool-repo").should eq "imgur.com/a"
    fn("https://www.imgur.com/a/ABCDEFG123/").should eq "imgur.com/a"
    fn("https://www.imgur.com/a/ABCDEFG123").should eq "imgur.com/a"
    fn("https://www.imgur.com/gallery/username/really-cool-repo/but-wait-theres-more").should eq "imgur.com/gallery"
    fn("https://www.imgur.com/gallery/username/really-cool-repo#literally-garbage").should eq "imgur.com/gallery"
    fn("https://www.imgur.com/gallery/username/really-cool-repo").should eq "imgur.com/gallery"
    fn("https://www.imgur.com/gallery/username/").should eq "imgur.com/gallery"
    fn("https://www.imgur.com/gallery/username").should eq "imgur.com/gallery"
    fn("https://www.imgur.com/somerandom").should eq "imgur.com"
  end
end
