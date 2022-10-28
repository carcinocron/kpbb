struct Kpbb::DraftChannelLog
  property user_id : Int64?
  property channel_id : Int64?
  property post_id : Int64?
  property comment_id : Int64?
  property action : Kpbb::ChannelAction
  property data : String?

  def initialize(@action : Kpbb::ChannelAction, @data : String? = nil)
  end
end
