@[Kpbb::Orm::Table(from: "ipaddresses")]
struct Kpbb::Ipaddress
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("ipaddress_id")
  Kpbb::Util::Model.base62_url("/ipaddresses")
  @@table = "ipaddresses"

  def self.select_columns : Array(String)
    ["id", "value::TEXT as value", "lastseen_at", "created_at"]
  end

  property id : Int64
  property value : String
  property lastseen_at : Time
  property created_at : Time

  def initialize(@id : Int64, @value : String, @lastseen_at : Time, @created_at : Time)
  end

  @@ip_id_cache = Hash(String, Int64).new

  def self.cached_upsert_id(value : String) : Int64
    unless @@ip_id_cache[value]?
      @@ip_id_cache[value] = self.upsert!(value).id
    end
    @@ip_id_cache[value]
  end

  def self.upsert!(value : String, connection : DB::Connection? = nil) : self
    connection ||= Kpbb.db
    id, lastseen_at, created_at = Kpbb.db.query_one(<<-SQL,
      INSERT INTO #{@@table} (value, lastseen_at, created_at)
      VALUES ($1, NOW(), NOW())
      ON CONFLICT (value) DO UPDATE SET lastseen_at = excluded.lastseen_at
      returning id, lastseen_at, created_at
    SQL


      args: [
        value,
      ], as: {Int64, Time, Time})
    return self.new(id, value, lastseen_at, created_at)
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
      where << "#{@@table}.value::TEXT ILIKE #{nqm.next}"
      bindings << env.params.query["value"]?
    end
    # pagination_before_after "ipaddresses"

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
