struct Kpbb::Youtube::VideoSnippet::ThumbnailBag
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_string_key(video_id)
  # Kpbb::Util::Model.find_by_http_env("youtube_video_id")
  @@table = "youtube_video_snippets"

  def self.select_columns : Array(String)
    ["video_id",
     "channel_id",
     # "youtube_video_snippets.data -> 'snippet' ->> 'channelId' as channel_id",
     "youtube_video_snippets.data -> 'snippet' ->> 'channelTitle' as channel_title",
     "youtube_video_snippets.data -> 'snippet' ->> 'title' as title",
     "youtube_video_snippets.data -> 'snippet' -> 'thumbnails' as thumbnails",
     "published_at"]
  end

  property video_id : String?
  property channel_id : String?
  property channel_title : String?
  property title : String?
  property thumbnails : String?
  property published_at : Time?

  def initialize(
    @video_id : String,
    @channel_id : String,
    @channel_title : String,
    @title : String,
    @thumbnails : String? = nil,
    @published_at : Time? = nil
  )
  end

  def initialize(rs : DB::ResultSet)
    @video_id = rs.read(typeof(@video_id))
    @channel_id = rs.read(typeof(@channel_id))
    @channel_title = rs.read(typeof(@channel_title))
    @title = rs.read(typeof(@title))
    thumbnails = rs.read(JSON::Any?)
    @thumbnails = thumbnails.nil? ? nil : thumbnails.to_json
    @published_at = rs.read(Time?)
  end

  def thumbnails : Hash(String, Kpbb::Youtube::VideoThumbnail)
    if v = @thumbnails
      Hash(String, Kpbb::Youtube::VideoThumbnail).from_json(v)
    else
      Hash(String, Kpbb::Youtube::VideoThumbnail).new
    end
  end
end
