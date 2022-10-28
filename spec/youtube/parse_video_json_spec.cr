require "../spec_helper"
require "../../src/markdown"

describe "Youtube::ParseVideoJson" do
  it "parse" do
    list = Kpbb::Youtube::VideoList.from_json(SAMPLE_JSON)

    list.items.size.should eq 1
    list.items[0].snippet.title.should eq "Nice and cool video from my favorite video hosting website"
    list.items[0].snippet.channel_title.should eq "Baroque Instant Bull"
    list.items[0].snippet.thumbnails.size.should eq 5
    list.items[0].snippet.thumbnails.has_key? "default"
    list.items[0].snippet.thumbnails.has_key? "medium"
    list.items[0].snippet.thumbnails.has_key? "high"
    list.items[0].snippet.thumbnails.has_key? "standard"
    list.items[0].snippet.thumbnails.has_key? "maxres"
    list.items[0].content_details.duration.should eq "PT3M6S"
    list.items[0].snippet.published_at.should be_a Time
    list.items[0].snippet.tags.should be_a Array(String)
    # pp list
  end
end

private SAMPLE_JSON = <<-JSON
{
  "kind": "youtube#videoListResponse",
  "etag": "qwertyuiopasdfghjklzxcvbnm1",
  "items": [
    {
      "kind": "youtube#video",
      "etag": "asdfghjkl1234567890zxcvbnmp",
      "id": "abcdefghijk",
      "snippet": {
        "publishedAt": "2021-01-11T11:11:11Z",
        "channelId": "ABCEDEFGHIJKLMNOAQRSTUVW",
        "title": "Nice and cool video from my favorite video hosting website",
        "description": "Pretty awesome description.",
        "thumbnails": {
          "default": {
            "url": "https://i.ytimg.com/vi/KOB5ecV-s9Q/default.jpg",
            "width": 120,
            "height": 90
          },
          "medium": {
            "url": "https://i.ytimg.com/vi/KOB5ecV-s9Q/mqdefault.jpg",
            "width": 320,
            "height": 180
          },
          "high": {
            "url": "https://i.ytimg.com/vi/KOB5ecV-s9Q/hqdefault.jpg",
            "width": 480,
            "height": 360
          },
          "standard": {
            "url": "https://i.ytimg.com/vi/KOB5ecV-s9Q/sddefault.jpg",
            "width": 640,
            "height": 480
          },
          "maxres": {
            "url": "https://i.ytimg.com/vi/KOB5ecV-s9Q/maxresdefault.jpg",
            "width": 1280,
            "height": 720
          }
        },
        "channelTitle": "Baroque Instant Bull",
        "tags": [
          "tag 1",
          "2021 tag",
          "tag 2",
          "cool tag",
          "kpbb",
          "never gonna",
          "nice"
        ],
        "categoryId": "25",
        "liveBroadcastContent": "none",
        "defaultLanguage": "en",
        "localized": {
          "title": "Nice and cool video from my favorite video hosting website",
          "description": "Pretty awesome description."
        },
        "defaultAudioLanguage": "en"
      },
      "contentDetails": {
        "duration": "PT3M6S",
        "dimension": "2d",
        "definition": "hd",
        "caption": "true",
        "licensedContent": true,
        "contentRating": {},
        "projection": "rectangular"
      },
      "topicDetails": {
        "relevantTopicIds": [
          "/m/098wr",
          "/m/098wr"
        ],
        "topicCategories": [
          "https://en.wikipedia.org/wiki/Society"
        ]
      }
    }
  ],
  "pageInfo": {
    "totalResults": 1,
    "resultsPerPage": 1
  }
}
JSON
