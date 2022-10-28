require "http"
require "json"

module Kpbb::Youtube
  # uses 100 units (normal lists are 1 unit)
  # order: date, rating, relevence, title, videoCount, viewCount
  # video_duration: any, long (>20), medium (20<=..>=4), short (<4)
  # max_results: default:15 # 0..50, default 5
  # published_after: RFC 3339
  # published_before: RFC 3339
  # video_definition: any, high, standard
  def self.fetch_search(
    search_query : String,
    order : String,
    topic_id : String? = nil,
    video_definition : String? = nil,
    max_results : Int16 = 15,
    video_dimension : String = "2d",
    video_duration : String? = nil,
    published_after : String? = nil,
    published_before : String? = nil
  ) : VideoList
    return VideoList.new unless search_query.size > 0
    returned_id_list = Array(String).new
    bindings = Array(String).new
    # client = HTTP::Client.new("www.googleapis.com", tls: true)

    body = HTTP::Params.build do |form|
      form.add "key", YOUTUBE_API_KEY
      # form.add "part", "snippet,topicDetails,contentDetails,localizations,suggestions"
      form.add "part", "snippet"
      form.add "maxResults", max_results.to_s
      form.add "order", order
      form.add "type", "video"
      form.add "videoDimension", video_dimension
      form.add "videoDefinition", video_definition if video_definition
      form.add "videoEmbeddable", "true"
      #  restrict a search to only videos that can be played outside youtube.com
      form.add "videoSyndicated", "true"
      form.add "q", search_query
      form.add "topicId", topic_id if topic_id
      form.add "publishedAfter", published_after if published_after
      form.add "publishedBefore", published_before if published_before
      form.add "videoDuration", video_duration if video_duration
    end

    url = "/youtube/v3/search?#{body}"
    res = client.get url, headers: HEADERS

    list = VideoList.from_json res.body
    list
  end
end
