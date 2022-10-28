require "json"

module Kpbb::Youtube
  struct VideoList
    include JSON::Serializable

    def initialize
    end

    property kind : String?
    property etag : String?
    default_new items : Array(Video)
    @[JSON::Field(key: "pageInfo")]
    default_new page_info : Hash(String, JSON::Any)
  end

  struct Video
    include JSON::Serializable

    def initialize
    end

    property kind : String?
    property etag : String?
    property id : String | VideoIdObj | Nil

    def id : String?
      case id_raw = @id
      when String
        id_raw
      when VideoIdObj
        id_raw.video_id
      else
        nil
      end
    end

    default_new snippet : VideoSnippet
    @[JSON::Field(key: "contentDetails")]
    default_new content_details : VideoContentDetails
    @[JSON::Field(key: "topicDetails")]
    default_new topic_details : VideoTopicDetails

    def one_liner : String
      "#{snippet.published_at} #{id} | #{snippet.channel_title} - #{snippet.title}"
    end
  end

  struct VideoSnippetLocalized
    include JSON::Serializable

    def initialize
    end

    property title : String?
    property description : String?
  end

  # when searching for videos, you get this
  # when /list for videos, you get a string
  struct VideoIdObj
    include JSON::Serializable

    def initialize
    end

    property kind : String?
    @[JSON::Field(key: "videoId")]
    property video_id : String?
  end

  struct VideoSnippet
    include JSON::Serializable

    def initialize
    end

    @[JSON::Field(key: "publishedAt")]
    property published_at : Time?
    @[JSON::Field(key: "channelId")]
    property channel_id : String?
    property title : String?
    property description : String?
    default_new thumbnails : Hash(String, VideoThumbnail)

    @[JSON::Field(key: "channelTitle")]
    property channel_title : String?
    default_new tags : Array(String)

    @[JSON::Field(key: "categoryId")]
    property category_id : String?
    @[JSON::Field(key: "liveBroadcastContent")]
    property live_broadcast_content : String?
    @[JSON::Field(key: "defaultLanguage")]
    property default_language : String?
    default_new localized : VideoSnippetLocalized
    @[JSON::Field(key: "defaultAudioLanguage")]
    property default_audio_language : String?
  end

  struct VideoContentDetails
    include JSON::Serializable

    def initialize
    end

    property duration : String?
    property dimension : String?
    property definition : String?
    property caption : String?
    @[JSON::Field(key: "licensedContent")]
    default_new licensed_content : JSON::Any
    @[JSON::Field(key: "contentRating")]
    default_new content_rating : JSON::Any
    property projection : String?
  end

  struct VideoTopicDetails
    include JSON::Serializable

    def initialize
    end

    @[JSON::Field(key: "relevantTopicIds")]
    default_new relevant_topic_ids : Array(String)
    @[JSON::Field(key: "topicCategories")]
    default_new topic_categories : Array(String)
  end

  struct VideoThumbnail
    include JSON::Serializable

    def initialize
    end

    property url : String?
    property width : Int64 | String | Nil
    property height : Int64 | String | Nil
  end
end
