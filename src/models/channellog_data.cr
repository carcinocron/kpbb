struct Kpbb::ChannelLogData
  include JSON::Serializable

  property job : Kpbb::ChannelJob?
  property rows_affected : Int64?
  property endpoint_id : Int64?

  def initialize(@job : Kpbb::ChannelJob? = nil, @rows_affected : Int64? = nil)
  end

  def initialize(@endpoint_id : Int64)
  end
end
