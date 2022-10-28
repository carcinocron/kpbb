@[Kpbb::Orm::Table(from: "loginattempts")]
struct Kpbb::Loginattempt
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("loginattempt_id")
  include Iom::CountryCode::HasCountryCodeNaturalKey
  @@table = "loginattempts"

  def self.select_columns : Array(String)
    ["id", "handle", "cc_i16", "ip::TEXT as ip", "success", "ua_id", "created_at"]
  end

  property id : Int64
  property handle : String
  property cc_i16 : Int16
  property ip : String?
  property success : Bool
  property ua_id : Int64
  property created_at : Time

  def initialize(
    @id : Int64,
    @handle : String,
    @cc_i16 : Int16,
    @ip : String?,
    @success : Bool,
    @ua_id : Int64,
    @created_at : Time
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @handle = rs.read(typeof(@handle))
    @cc_i16 = rs.read(Int16?) || 0_i16
    @ip = rs.read(String?)
    @success = rs.read(Bool)
    @ua_id = rs.read(Int64)
    @created_at = rs.read(Time)
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    if env.params.query["handle"]?.presence
      where << "#{@@table}.handle ILIKE #{nqm.next}"
      bindings << env.params.query["handle"]?
    end
    if cc_i16 = env.params.query["cc_i16"]?.presence
      where << "#{@@table}.cc_i16 = #{nqm.next}"
      bindings << cc_i16
    end
    pagination_before_after "loginattempts"

    if where.size > 0
      query += "WHERE " + where.join(" AND ")
    end
    query += " ORDER BY #{@@table}.id DESC"

    page = Page(self).new(env) do |page|
      pagination_offset_limit

      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { page.collection << self.new(rs) }
      end
      if env.params.query["before"]?.nil? && page.collection[0]
        page.morequery["before"] = (page.collection[0].id + 1).to_s
      end
    end
  end
end
