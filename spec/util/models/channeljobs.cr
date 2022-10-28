struct TestChannelJob
  property id : Int64
  property user_id : Int64?
  property channel_id : Int64?
  property post_id : Int64?
  property comment_id : Int64?
  property action : Kpbb::ChannelAction
  property data : String?
  property run_at : Time # earliest time to run task
  property queued : Bool # when queued=true, task might be delayed in favor of earlier scheduled tasks
  property created_at : Time

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @user_id = rs.read(Int64?)
    @channel_id = rs.read(Int64?)
    @post_id = rs.read(Int64?)
    @comment_id = rs.read(Int64?)
    @action = Kpbb::ChannelAction.new (rs.read(Int16))
    # we're going to keep this as TEXT during runtime
    # to not anger the type system
    # but also because channeljobs are low priority for scaling
    data = rs.read(JSON::Any?)
    @data = data.nil? ? nil : data.to_json
    @run_at = rs.read(Time)
    @queued = rs.read(Bool)
    @created_at = rs.read(Time)
  end

  def initialize(
    @run_at : Time,
    @action : Kpbb::ChannelAction,
    @user_id : Int64? = nil,
    @channel_id : Int64? = nil,
    @post_id : Int64? = nil,
    @comment_id : Int64? = nil,
    @data : String? = nil,
    @queued : Bool = true
  )
    @id, @created_at = Kpbb.db.query_one(<<-SQL,
      INSERT INTO channeljobs (user_id, channel_id, post_id, comment_id, action, data, run_at, queued, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
      returning id, created_at
    SQL
      args: [
        @user_id,
        @channel_id,
        @post_id,
        @comment_id,
        @action.value,
        @data,
        @run_at,
        @queued,
      ], as: {Int64, Time})
  end

  def initialize(@id : Int64)
    query = <<-SQL
      SELECT user_id, channel_id, post_id, comment_id, action, data, run_at, queued, created_at
      FROM channeljobs WHERE id = $1
    SQL

    @user_id, @channel_id, @post_id, @comment_id, action, data, @run_at, @queued, @created_at = Kpbb.db.query_one(query, args: [@id], as: {
      Int64?,
      Int64?,
      Int64?,
      Int64?,
      Int16,
      JSON::Any?,
      Time,
      Bool,
      Time,
    })
    @data = data.to_json
    @action = Kpbb::ChannelAction.new(action.to_i32)
  end

  def self.all : Array(self)
    list = Array(self).new
    query = <<-SQL
      SELECT id, user_id, channel_id, post_id, comment_id, action, data, run_at, queued, created_at
      FROM channeljobs
    SQL
    Kpbb.db.query(query) do |rs|
      rs.each { list << self.new(rs) }
    end
    list
  end
end
