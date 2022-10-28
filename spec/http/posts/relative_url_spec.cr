require "../../spec_helper"

describe "Http::Posts::RelativeUrl" do
  it "uses title when slugged" do
    empty_db
    user1 = TestUser.new(handle: "username1")
    channel = Kpbb::Channel.factory(dname: "channel1", creator_id: user1.id, listed: true, public: true)
    post = Kpbb::Post.factory(channel_id: channel.id, title: "A Cool Post 123", creator_id: user1.id, draft: false)

    expected_relative_url = "/posts/#{post.id.to_b62}"
    expected_relative_title_url = "/posts/a-cool-post-123-#{post.id.to_b62}"

    post.relative_url.should eq expected_relative_url
    post.relative_title_url.should eq expected_relative_title_url

    "a-cool-post-123-g8".to_i64_from_slug_prefixed_b62?.should eq post.id

    creating_post = Kpbb::Request::Post::Creating.new(
      body: HTTP::Params.from_hash(Hash(String, String){
        "title" => post.title.not_nil!,
      }),
      creator_id: post.creator_id.not_nil!)
    creating_post.id = post.id
    creating_post.relative_url.should eq expected_relative_url
    creating_post.relative_title_url.should eq expected_relative_title_url
  end
end
