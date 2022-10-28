@[Kpbb::Orm::Table(from: "referers")]
struct Kpbb::Referer
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("referer_id")
  Kpbb::Util::Model.base62_url("/referers")
  @@table = "referers"

  def self.select_columns : Array(String)
    ["id", "value", "lastseen_at", "created_at"]
  end

  property id : Int64
  property value : String
  property lastseen_at : Time
  property created_at : Time

  def initialize(@id : Int64, @value : String, @lastseen_at : Time, @created_at : Time)
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @value = rs.read(String)
    @lastseen_at = rs.read(Time)
    @created_at = rs.read(Time)
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    if env.params.query["value"]?.presence && env.session.userId?
      where << "#{@@table}.value ILIKE #{nqm.next}"
      bindings << env.params.query["value"]?
    end
    # pagination_before_after "referer"

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
