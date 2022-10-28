struct Kpbb::DraftChannelJob
  property user_id : Int64?
  property channel_id : Int64?
  property post_id : Int64?
  property comment_id : Int64?
  property action : Kpbb::ChannelAction
  property data : String?
  property run_at : Time # earliest time to run task
  property queued : Bool # when queued=true, task might be delayed in favor of earlier scheduled tasks

  def initialize(@action : Kpbb::ChannelAction, @run_at : Time, @queued : Bool, @data : String? = nil)
  end
end
