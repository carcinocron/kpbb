@[Kpbb::Orm::Table(from: "channeljobs")]
struct Kpbb::ChannelJob
  include JSON::Serializable
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("channeljob_id")
  @@table = "channeljobs"

  def self.select_columns : Array(String)
    ["id", "user_id", "channel_id", "post_id", "comment_id", "action", "data", "run_at", "queued", "created_at"]
  end

  @[Kpbb::Orm::Column(insert: false, insert_return: true)]
  property id : Int64
  @[Kpbb::Orm::Column]
  property user_id : Int64?
  @[Kpbb::Orm::Column]
  property channel_id : Int64?
  @[Kpbb::Orm::Column]
  property post_id : Int64?
  @[Kpbb::Orm::Column]
  property comment_id : Int64?
  @[Kpbb::Orm::Column]
  property action : Kpbb::ChannelAction
  @[Kpbb::Orm::Column]
  property data : String?
  @[Kpbb::Orm::Column]
  property run_at : Time # earliest time to run task
  @[Kpbb::Orm::Column]
  property queued : Bool # when queued=true, task might be delayed in favor of earlier scheduled tasks
  @[Kpbb::Orm::Column(insert: "NOW()", insert_return: true)]
  property created_at : Time

  def initialize(@id : Int64, @user_id : Int64?, @channel_id : Int64?, @post_id : Int64?, @comment_id : Int64?, @action : Kpbb::ChannelAction, @data : String? = nil, @run_at : Time = Time.utc, @queued : Bool = true, @created_at : Time = Time.utc)
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @user_id = rs.read(Int64?)
    @channel_id = rs.read(Int64?)
    @post_id = rs.read(Int64?)
    @comment_id = rs.read(Int64?)
    @action = Kpbb::ChannelAction.new rs.read(Int16)
    # we're going to keep this as TEXT during runtime
    # to not anger the type system
    # but also because channeljobs are low priority for scaling
    data = rs.read(JSON::Any?)
    @data = data.nil? ? nil : data.to_json
    @run_at = rs.read(Time)
    @queued = rs.read(Bool)
    @created_at = rs.read(Time)
  end

  def self.save!(run_at : Time, action : Kpbb::ChannelAction, user_id : Int64? = nil, channel_id : Int64? = nil, post_id : Int64? = nil, comment_id : Int64? = nil, data : String? = nil, queued : Bool = true, connection : DB::Connection? = nil)
    connection ||= Kpbb.db
    data = nil if data == ""
    query = <<-SQL
      INSERT INTO #{{{ @type.annotation(Kpbb::Orm::Table)[:from] }}} (user_id, channel_id, post_id, comment_id, action, data, run_at, queued, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, COALESCE($7, NOW()), $8, NOW())
      returning id, created_at, run_at
    SQL
    id, created_at, run_at = Kpbb.db.query_one(query, args: [
      user_id,
      channel_id,
      post_id,
      comment_id,
      action.value,
      data,
      run_at,
      queued,
    ], as: {Int64, Time, Time})
    return self.new(id, user_id, channel_id, post_id, comment_id, action, data, run_at, queued, created_at)
  end

  def self.upsert!(run_at : Time, action : Kpbb::ChannelAction, user_id : Int64? = nil, channel_id : Int64? = nil, post_id : Int64? = nil, comment_id : Int64? = nil, data : String? = nil, queued : Bool = true, connection : DB::Connection? = nil)
    connection ||= Kpbb.db
    data = nil if data == ""
    query = <<-SQL
      UPDATE #{@@table}
      SET run_at = $1, queued = $2, data = $3
      WHERE user_id = $4
      AND channel_id = $5
      AND post_id = $6
      AND comment_id = $7
      AND action = $8
      returning id
    SQL
    bindings = [
      run_at,
      queued,
      data,
      user_id,
      channel_id,
      post_id,
      comment_id,
      action.value,
    ]
    result : DB::ExecResult = Kpbb.db.exec(query, args: bindings)
    # puts result
    if result.rows_affected == 0
      self.save!(
        run_at: run_at.not_nil!,
        action: action,
        user_id: user_id,
        channel_id: channel_id,
        post_id: post_id,
        comment_id: comment_id,
        data: data,
        queued: queued)
    end
    nil
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "#{select_from} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    if env.params.query["action"]?.presence
      where << "action = "
      bindings << env.params.query["action"]?
    end

    channel_id = (env.params.url["channel_id"]? || env.params.query["channel_id"]?).try(&.to_i64_from_b62?)
    if channel_id
      where << "channel_id = #{nqm.queued}"
      bindings << channel_id
    end

    post_id = (env.params.url["post_id"]? || env.params.query["post_id"]?).try(&.to_i64_from_b62?)
    if post_id
      where << "post_id = #{nqm.queued}"
      bindings << post_id
    end

    comment_id = (env.params.url["comment_id"]? || env.params.query["comment_id"]?).try(&.to_i64_from_b62?)
    if comment_id
      where << "comment_id = #{nqm.queued}"
      bindings << comment_id
    end

    user_id = (env.params.url["user_id"]? || env.params.query["user_id"]?).try(&.to_i64_from_b62?)
    if user_id
      where << "user_id = #{nqm.queued}"
      bindings << user_id
    end

    pagination_before_after "channeljobs"

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

  def self.all_for_minute(minute : Time, connection : DB::Connection? = nil) : Array(self)
    # if a transaction connection was given,
    # then we must select for update
    for_update : Bool = !connection.nil?
    connection ||= Kpbb.db
    list = Array(self).new
    query = <<-SQL
    SELECT
      #{self.select}
    FROM #{@@table}
    WHERE #{@@table}.run_at <= $1
    ORDER BY #{@@table}.run_at ASC
    #{for_update ? " FOR UPDATE" : ""}
    LIMIT 25
    SQL
    bindings = [minute]
    Kpbb.db.query(query, args: bindings) do |rs|
      rs.each { list << self.new(rs) }
    end
    list.sort! { |a, b| a.id <=> b.id }
    list.sort! { |a, b| a.run_at <=> b.run_at }
    list.sort! { |a, b| a.queued.to_i16 <=> b.queued.to_i16 }
    list
  end
end
