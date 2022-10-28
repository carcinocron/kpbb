@[Kpbb::Orm::Table(from: "channellogs")]
struct Kpbb::ChannelLog
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("channellog_id")
  @@table = "channellogs"

  def self.select_columns : Array(String)
    ["id", "user_id", "channel_id", "post_id", "comment_id", "action", "data", "created_at"]
  end

  @[Kpbb::Orm::Column(insert: false, insert_return: true)]
  property id : Int64
  property user_id : Int64?
  property channel_id : Int64?
  property post_id : Int64?
  property comment_id : Int64?
  property action : Kpbb::ChannelAction
  property data : String?
  property created_at : Time

  def initialize(@id : Int64, @user_id : Int64?, @channel_id : Int64?, @post_id : Int64?, @comment_id : Int64?, @action : Kpbb::ChannelAction, @data : String? = nil, @created_at : Time = Time.utc)
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @user_id = rs.read(Int64?)
    @channel_id = rs.read(Int64?)
    @post_id = rs.read(Int64?)
    @comment_id = rs.read(Int64?)
    @action = Kpbb::ChannelAction.new(rs.read(Int16))
    # we're going to keep this as TEXT during runtime
    # to not anger the type system
    # but also because channellogs are low priority for scaling
    @data = rs.read(JSON::Any?).to_json
    @created_at = rs.read(Time)
  end

  def self.save!(action : Kpbb::ChannelAction, user_id : Int64? = nil, channel_id : Int64? = nil, post_id : Int64? = nil, comment_id : Int64? = nil, data : String? = nil, connection : DB::Connection? = nil)
    connection ||= Kpbb.db
    data = nil if data == ""
    id, created_at = connection.query_one(<<-SQL,
      INSERT INTO #{@@table} (user_id, channel_id, post_id, comment_id, action, data, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, NOW())
      returning id, created_at
    SQL


      args: [
        user_id,
        channel_id,
        post_id,
        comment_id,
        action.value,
        data,
      ], as: {Int64, Time})
    return self.new(id, user_id, channel_id, post_id, comment_id, action, data, created_at)
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    if env.params.query["action"]?.presence
      where << "action = "
      bindings << env.params.query["action"]?
    end

    channel_id = (env.params.url["channel_id"]? || env.params.query["channel_id"]?).try(&.to_i64_from_b62?)
    if channel_id
      where << "channel_id = #{nqm.next}"
      bindings << channel_id
    end

    post_id = (env.params.url["post_id"]? || env.params.query["post_id"]?).try(&.to_i64_from_b62?)
    if post_id
      where << "post_id = #{nqm.next}"
      bindings << post_id
    end

    comment_id = (env.params.url["comment_id"]? || env.params.query["comment_id"]?).try(&.to_i64_from_b62?)
    if comment_id
      where << "comment_id = #{nqm.next}"
      bindings << comment_id
    end

    user_id = (env.params.url["user_id"]? || env.params.query["user_id"]?).try(&.to_i64_from_b62?)
    if user_id
      where << "user_id = #{nqm.next}"
      bindings << user_id
    end

    pagination_before_after "channellogs"

    if where.size > 0
      query += "WHERE " + where.join(" AND ")
    end

    page = Page(self).new env do |page|
      pagination_offset_limit
      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { page.collection << self.new(rs) }
      end
    end
  end
end
