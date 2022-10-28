require "json"
require "yaml"
# @link https://www.npmjs.com/package/unfurl.js
# @link https://github.com/jacktuck/unfurl/blob/master/src/types.ts
# in the original specification, not everything was nullable
# but in reality it seems that literally any property could be null

# added string because unfurl returns numbers from some websites as String
alias JsonNumber = Float64 | Int64 | String

module Iom::Unfurl
  alias AnyThumbnail = ObjectEmbedThumbnail | TwitterCard::Image | OpenGraph::Image

  struct MetadataResponse
    include JSON::Serializable
    include YAML::Serializable

    getter result : Metadata?
  end

  struct Metadata
    include JSON::Serializable
    include YAML::Serializable

    getter title : String?
    getter description : String?
    getter keywords : Array(String)?
    getter oEmbed : ObjectEmbed?
    getter twitter_card : TwitterCard?
    getter open_graph : OpenGraph?

    def thumbnail : String?
      t : String? = nil
      if t = @open_graph.try(&.images.try { |i| i.[0]?.try(&.url) }).presence
        return t
      end
      if t = @twitter_card.try(&.images.try { |i| i.[0]?.try(&.url) }).presence
        return t
      end
      if t = @oEmbed.try(&.thumbnails.try { |i| i.[0]?.try(&.url) }).presence
        return t
      end
      return nil
    end

    def all_thumbnails : Array(AnyThumbnail)
      list = Array(AnyThumbnail).new
      if otherlist = @open_graph.try(&.images)
        list += otherlist
      end
      # no height or width property?
      # if otherlist = @twitter_card.try(&.images)
      #   list += otherlist
      # end
      if otherlist = @oEmbed.try(&.thumbnails)
        list += otherlist
      end
      list.compact!
    end

    def largest_thumbnail? : AnyThumbnail?
      all_thumbnails.max_by? do |thumb|
        h : Int32? = thumb.height.try(&.to_i32?)
        w : Int32? = thumb.width.try(&.to_i32?)
        (h || 0_i32) * (w || 0_i32)
      end
    end
  end

  struct ObjectEmbed
    include JSON::Serializable
    include YAML::Serializable

    getter type : String? # 'photo' | 'video' | 'link' | 'rich' | 'article'
    getter version : String | JsonNumber | Nil
    getter title : String?
    getter author_name : String?
    getter author_url : String?
    getter provider_name : String?
    getter provider_url : String?
    getter cache_age : JsonNumber?
    getter thumbnails : Array(ObjectEmbedThumbnail)?

    def photo? : Bool
      @type == "photo"
    end

    def video? : Bool
      @type == "video"
    end

    def link? : Bool
      @type == "link"
    end

    def rich? : Bool
      @type == "rich"
    end

    def article? : Bool
      @type == "article"
    end
  end

  struct ObjectEmbedThumbnail
    include JSON::Serializable
    include YAML::Serializable

    getter url : String?
    getter width : JsonNumber?
    getter height : JsonNumber?
  end

  struct TwitterCard
    include JSON::Serializable
    include YAML::Serializable

    getter card : String?
    getter site : String?
    getter creator : String?
    getter creator_id : String?
    getter title : String?
    getter description : String?
    getter players : Array(TwitterCard::Player)?
    getter apps : TwitterCard::AppBag?
    getter images : Array(TwitterCard::Image)?
  end

  struct TwitterCard::Player
    include JSON::Serializable
    include YAML::Serializable

    getter url : String?
    getter stream : String?
    getter height : JsonNumber?
    getter width : JsonNumber?
  end

  struct TwitterCard::AppBag
    include JSON::Serializable
    include YAML::Serializable

    getter iphone : TwitterCard::AppItem?
    getter ipad : TwitterCard::AppItem?
    getter googleplay : TwitterCard::AppItem?
  end

  struct TwitterCard::AppItem
    include JSON::Serializable
    include YAML::Serializable

    getter id : String?
    getter name : String?
    getter url : String?
  end

  struct TwitterCard::Image
    include JSON::Serializable
    include YAML::Serializable

    getter url : String?
    getter alt : String?

    # not actually in the data
    getter height : JsonNumber?
    getter width : JsonNumber?
  end

  struct OpenGraph
    include JSON::Serializable
    include YAML::Serializable

    getter title : String?
    getter type : String?
    getter images : Array(OpenGraph::Image)?
    getter url : String?
    getter audio : Array(OpenGraph::Audio)?
    getter description : String?
    getter determiner : String?
    getter locale : String?
    getter locale_alt : String?
    getter videos : Array(OpenGraph::Video)?
  end

  struct OpenGraph::Image
    include JSON::Serializable
    include YAML::Serializable

    getter url : String?
    getter secure_url : String?
    getter type : String?
    getter height : JsonNumber?
    getter width : JsonNumber?
  end

  struct OpenGraph::Audio
    include JSON::Serializable
    include YAML::Serializable

    getter url : String?
    getter secure_url : String?
    getter type : String?
  end

  struct OpenGraph::Video
    include JSON::Serializable
    include YAML::Serializable

    getter url : String?
    getter stream : String?
    getter height : JsonNumber?
    getter width : JsonNumber?
    getter tags : Array(String)?
  end
end
