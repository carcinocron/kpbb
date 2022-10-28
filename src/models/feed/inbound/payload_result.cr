struct Kpbb::Feed::Inbound::Payload::Result
  include JSON::Serializable
  include YAML::Serializable

  property errors : Hash(String, Array(String))? { Hash(String, Array(String)).new }
  property post_id : Int64?

  def initialize
  end
end
