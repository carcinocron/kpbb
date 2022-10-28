struct Kpbb::Flair::Bot
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("bot_id")
  @@table = "flair.bots"

  def self.select_columns : Array(String)
    ["id", "handle", "bio", "avatar", "lastactive_at", "created_at", "updated_at"]
  end

  property id : Int64
  property handle : String
  property bio : String?
  @[Kpbb::Orm::Column]
  str_getter avatar
  @[Kpbb::Orm::Column]
  str_getter banner

  def initialize(
    @id : Int64,
    @handle : String,
    @bio : String?,
    @avatar : String?,
    @lastactive_at : Time,
    @created_at : Time,
    @updated_at : Time
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @handle = rs.read(typeof(@handle))
    @bio = rs.read(typeof(@bio))
    @avatar = rs.read(String?)
    @lastactive_at = rs.read(Time)
    @created_at = rs.read(Time)
    @updated_at = rs.read(Time)
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    # bot_id = env.session.userId?
    # pagination_before_after "flair.bots"
    # if where.size > 0
    #   query += "WHERE "+where.join(" AND ")
    # end

    page = Page(self).new env do |page|
      pagination_offset_limit
      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { page.collection << self.new(rs) }
      end
    end
  end
end
