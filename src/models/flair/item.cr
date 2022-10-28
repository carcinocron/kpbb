struct Kpbb::Flair::Item
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("post_id")
  @@table = "flair.items"

  def self.select_columns : Array(String)
    ["id", "bot_id", "key", "line", "body_md", "body_html", "active", "lastactive_at", "created_at", "updated_at"]
  end

  property id : Int64
  property bot_id : Int64
  property key : String     # unique (bot_id, key) identifier
  property line : String    # one-liner
  property body_md : String # optional
  property body_html : String
  property active : Bool
  property lastactive_at : Time
  property updated_at : Time
  property created_at : Time

  def initialize(
    @id : Int64,
    @bot_id : Int64,
    @key : String,
    @line : String,
    @body_md : String,
    @body_html : String,
    @active : Bool = true,
    @lastactive_at : Time = Time.utc,
    @updated_at : Time = Time.utc,
    @created_at : Time = Time.utc
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @bot_id = rs.read(Int64)
    @key = rs.read(String)
    @line = rs.read(String)
    @body_md = rs.read(String)
    @body_html = rs.read(String)
    @active = rs.read(Bool)
    @lastactive_at = rs.read(Time)
    @created_at = rs.read(Time)
    @updated_at = rs.read(Time)
  end

  def self.save!(
    bot_id : Int64,
    key : String,
    line : String,
    body_md : String,
    body_html : String,
    active : Bool,
    lastactive_at : Time = Time.utc
  ) : Int64
    id = Kpbb.db.query_one(<<-SQL,
      INSERT INTO comments (bot_id, key, line, body_md, body_html, active, lastactive_at, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
      returning id
    SQL
      args: [
        bot_id,
        key,
        line,
        body_md,
        body_html,
        active,
        lastactive_at,
      ], as: Int64)
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM comments "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    if env.session.userId?
      if env.params.query.truthy?("active")
        where << "comments.active IS TRUE"
      elsif env.params.query.falsey?("active")
        where << "comments.active IS FALSE"
      end
    end

    if bot_id = (env.params.url["bot_id"]? || env.params.query["bot_id"]?).try(&.to_i64_from_b62?)
      where << "comments.bot_id = #{nqm.next}"
      bindings << bot_id
    end

    if where.size > 0
      query += "WHERE " + where.join(" AND ")
    end

    Page(self).new env do |page|
      pagination_offset_limit
      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { page.collection << self.new(rs) }
      end
    end
  end
end
