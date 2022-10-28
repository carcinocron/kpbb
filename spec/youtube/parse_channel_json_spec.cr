require "../spec_helper"
require "../../src/markdown"

describe "Youtube::ParseChannelJson" do
  it "parse" do
    list = Kpbb::Youtube::ChannelList.from_json(SAMPLE_JSON)

    list.items.size.should eq 1
    list.items[0].snippet.title.should eq "Cool Channel Title"
    list.items[0].snippet.description.should eq "Very Cool and Stuff"
    list.items[0].snippet.thumbnails.size.should eq 3
    list.items[0].snippet.thumbnails.has_key? "default"
    list.items[0].snippet.thumbnails.has_key? "medium"
    list.items[0].snippet.thumbnails.has_key? "high"
    list.items[0].snippet.published_at.should be_a Time
    # pp list
  end
end

private SAMPLE_JSON = <<-JSON
{
  "kind": "youtube#channelListResponse",
  "etag": "asdfghjklqwertyuiopzxcvbnmu",
  "pageInfo": {
    "totalResults": 1,
    "resultsPerPage": 5
  },
  "items": [
    {
      "kind": "youtube#channel",
      "etag": "zawesxrdcvtgbyhunjimilkjhgf",
      "id": "q2w3e4r5t6y7u8i9o0pxdcfv",
      "snippet": {
        "title": "Cool Channel Title",
        "description": "Very Cool and Stuff",
        "customUrl": "somehandlelikestring",
        "publishedAt": "2009-09-04T18:43:19Z",
        "thumbnails": {
          "default": {
            "url": "https://yt3.ggpht.com/ytc/AAUvwniLlYxRlHTLXQAcquIdKF4Xow5kQ_trGxWvUPsF2g=s88-c-k-c0x00ffffff-no-rj",
            "width": 88,
            "height": 88
          },
          "medium": {
            "url": "https://yt3.ggpht.com/ytc/AAUvwniLlYxRlHTLXQAcquIdKF4Xow5kQ_trGxWvUPsF2g=s240-c-k-c0x00ffffff-no-rj",
            "width": 240,
            "height": 240
          },
          "high": {
            "url": "https://yt3.ggpht.com/ytc/AAUvwniLlYxRlHTLXQAcquIdKF4Xow5kQ_trGxWvUPsF2g=s800-c-k-c0x00ffffff-no-rj",
            "width": 800,
            "height": 800
          }
        },
        "localized": {
          "title": "Cool Channel Title",
          "description": "Very Cool and Stuff"
        },
        "country": "US"
      }
    }
  ]
}
JSON
