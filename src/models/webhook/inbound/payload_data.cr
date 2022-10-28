struct Kpbb::Webhook::Inbound::Payload::Data
  include JSON::Serializable

  property body : Hash(String, String)? { Hash(String, String).new }
  property creator_id : Int64?

  def initialize(
    @body : Hash(String, String)? = nil,
    @creator_id : Int64? = nil
  )
  end
end
