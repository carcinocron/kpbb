require "xml"
require "../../../spec_helper"

describe "Html::Post::Row::Toot" do
  it "renders toot" do
    empty_db
    u1 = TestUser.new(handle: "username1")
    channel1 = Kpbb::Channel.factory(creator_id: u1.id)
    p0 = Kpbb::Post.factory(posted: true, creator_id: u1.id, channel_id: channel1.id, draft: false)
    # p1 = Kpbb::Post.factory(posted: false, creator_id: u1.id, channel_id: channel1.id, parent_id: p0.id)
    thread = Kpbb::Post::Thread.fetch(post_id: p0.id)

    html = Kpbb::Ecr::Component.post_row(
      ctx: u1.view_context(p0.relative_title_url),
      post: p0,
      thread: Kpbb::Post::Thread.fetch(post_id: p0.id, user: u1.to_public_user))

    doc = XML.parse_html(html)
    # pp doc.xpath_node("//*//h5")
    # pp doc.xpath_node("//h5")
    # n = doc.xpath_node("//div[contains(@class, 'post')]//div//h1//a").not_nil!
    # n["href"]?.should eq p0.relative_title_url
    # n.inner_text.strip.should eq p0.title

    # ns = doc.xpath_nodes("//div[contains(@class, 'media-body')]//h6//a")
    # pp ns.to_s
    # n[0]["href"]?.should eq u1.relative_url
    # n[0].inner_text.strip.should eq u1.username

    # n[0]["href"]?.should eq channel.relative_url
    # n[0].inner_text.strip.should eq channel.dname
  end
end

# nodes = (doc.xpath_nodes("//*[contains(@class, 'athing')]"))
# next unless comhead = el.xpath_node("./*//*[contains(@class, 'comhead')]")
# next unless comtext = el.xpath_node("./*//*[contains(@class, 'commtext')]")
# storyon = el.xpath_node("./*//*[contains(@class, 'storyon')]/a")
# username : String? = el.xpath_node("./*//a[contains(@class, 'hnuser')]").try(&.inner_text)
# parent_id : String? = el.xpath_node("./*//a[text() = 'parent']").try(&.["href"]?.try(&.sub("item?id=", "")))

# <img class="icon icon-48" src="/static/fi/0/file-text.svg" alt="No thumbnail" width="48" height="48"/>
# <div class="media-body">
#   <h5 class="mt-0">
#       <a href="/posts/post-title-g8">
#         post title      </a>
#   </h5>
#   <h6>
#       by
#       <a href="/users/username1">username1</a>
#       in
#       <a href="/channels/channel-name">
#         channel name      </a>
#     </h6><form class="d-inline" action="/posts/g8/users/me?return_to=/posts/post-title-g8" method="POST">
#   <input type="hidden" name="saved" value="1"/>
#   <button type="submit" class="nbtn">save</button>
# </form>
#     <form class="d-inline" action="/posts/g8/users/me?return_to=/posts/post-title-g8" method="POST">
#   <input type="hidden" name="hidden" value="1"/>
#   <button type="submit" class="nbtn">hide</button>
# </form>

#     <a href="/posts/post-title-g8">
#       0 comments
#     </a>

# </div>
