struct TestChannelLog
  property id : Int64
  property user_id : Int64?
  property channel_id : Int64?
  property post_id : Int64?
  property comment_id : Int64?
  property action : Kpbb::ChannelAction
  property data : String?
  property created_at : Time

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @user_id = rs.read(Int64?)
    @channel_id = rs.read(Int64?)
    @post_id = rs.read(Int64?)
    @comment_id = rs.read(Int64?)
    @action = Kpbb::ChannelAction.new(rs.read(Int16))
    # we're going to keep this as TEXT during runtime
    # to not anger the type system
    # but also because channeljobs are low priority for scaling
    @data = rs.read(JSON::Any?).to_json
    @created_at = rs.read(Time)
  end

  def initialize(
    @user_id : Int64?,
    @channel_id : Int64?,
    @post_id : Int64?,
    @comment_id : Int64?,
    @action : Kpbb::ChannelAction,
    @data : String?
  )
    @id, @created_at = Kpbb.db.query_one(<<-SQL,
      INSERT INTO channellogs (user_id, channel_id, post_id, comment_id, action, data, run_at, queued, created_at)
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
      ], as: Int64)
  end

  def initialize(@id : Int64)
    query = <<-SQL
      SELECT user_id, channel_id, post_id, comment_id, action, data, created_at
      FROM channellogs WHERE id = $1
    SQL

    @user_id, @channel_id, @post_id, @comment_id, action, data, @created_at = Kpbb.db.query_one(query, args: [@id], as: {
      Int64?,
      Int64?,
      Int64?,
      Int64?,
      Kpbb::ChannelAction,
      String?,
      Time,
      Bool,
      Time,
    })
    @action = Kpbb::ChannelAction.new(action)
    @data = data.to_json
  end

  def self.all : Array(self)
    list = Array(self).new
    query = <<-SQL
      SELECT id, user_id, channel_id, post_id, comment_id, action, data, created_at
      FROM channellogs
      ORDER BY id ASC
    SQL
    Kpbb.db.query(query) do |rs|
      rs.each { list << self.new(rs) }
    end
    list
  end
end
