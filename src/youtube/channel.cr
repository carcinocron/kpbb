require "json"

module Kpbb::Youtube
  struct ChannelList
    include JSON::Serializable

    def initialize
    end

    property kind : String?
    property etag : String?
    default_new items : Array(Channel)
    @[JSON::Field(key: "pageInfo")]
    default_new page_info : Hash(String, JSON::Any)
  end

  struct Channel
    include JSON::Serializable

    def initialize
    end

    property kind : String?
    property etag : String?
    property id : String?
    default_new snippet : ChannelSnippet

    def one_liner : String
      "#{@snippet.published_at} #{@id} | #{@snippet.channel_title} - #{@snippet.title}"
    end
  end

  struct ChannelSnippetLocalized
    include JSON::Serializable

    def initialize
    end

    property title : String?
    property description : String?
  end

  struct ChannelSnippet
    include JSON::Serializable

    def initialize
    end

    property title : String?
    property description : String?
    @[JSON::Field(key: "customUrl")]
    property custom_url : String?
    @[JSON::Field(key: "publishedAt")]
    property published_at : Time?
    default_new thumbnails : Hash(String, ChannelThumbnail)
    property country : String?
  end

  struct ChannelThumbnail
    include JSON::Serializable

    def initialize
    end

    property url : String?
    property width : Int64 | String | Nil
    property height : Int64 | String | Nil
  end
end
