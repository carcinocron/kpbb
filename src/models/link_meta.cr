require "yaml"

struct Kpbb::Link::Meta
  include JSON::Serializable
  include YAML::Serializable

  property youtube_id : String?
  property unfurl : Iom::Unfurl::Metadata?

  def initialize(@youtube_id : String)
  end

  def initialize(@unfurl : Iom::Unfurl::Metadata)
  end

  def initialize
  end
end
