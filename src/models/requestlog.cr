@[Kpbb::Orm::Table(from: "requestlogs")]
struct Kpbb::Requestlog
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("requestlog_id")
  include Iom::CountryCode::HasCountryCodeNaturalKey
  @@table = "requestlogs"

  def self.select_columns : Array(String)
    ["id", "path_with_query", "cc_i16", "ip::TEXT as ip", "referer_id", "ua_id", "duration", "user_id", "created_at"]
  end

  property id : Int64
  property path_with_query : String
  property cc_i16 : Int16
  property ip : String?
  property referer_id : Int64?
  property ua_id : Int64?
  property duration : Int16
  property user_id : Int64?
  property created_at : Time

  def initialize(
    @id : Int64,
    @path_with_query : String,
    @cc_i16 : Int16,
    @ip : String?,
    @referer_id : Int64?,
    @ua_id : Int64?,
    @duration : Int16,
    @user_id : Int64?,
    @created_at : Time
  )
  end

  def self.insert(
    useragent : String,
    referer : String,
    ipaddress : String?,
    path_with_query : String,
    cc_i16 : Int16,
    duration : Int32,
    user_id : Int64?
  )
    query = "CALL insert_requestlog($1, $2, $3, $4, $5, $6, $7)"
    bindings = [
      useragent,
      referer,
      ipaddress,
      path_with_query,
      cc_i16,
      duration,
      user_id,
    ]

    bc = ::Raven::Breadcrumb.record(
      data: {:bindings => bindings, :query => query},
      category: "db.query.manual")
    start_at = Time.monotonic
    begin
      Kpbb.db.exec query, args: bindings
    ensure
      bc.data[:duration] = (Time.monotonic - start_at).milliseconds.to_s + " ms"
    end
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @path_with_query = rs.read(String)
    @cc_i16 = rs.read(Int16?) || 0_i16
    @ip = rs.read(String?)
    @referer_id = rs.read(Int64?)
    @ua_id = rs.read(Int64?)
    @duration = rs.read(Int16)
    @user_id = rs.read(Int64?)
    @created_at = rs.read(Time)
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    if env.params.query["path_with_query"]?.presence
      where << "#{@@table}.path_with_query ILIKE #{nqm.next}"
      bindings << env.params.query["path_with_query"]?
    end
    if cc_i16 = env.params.query["cc_i16"]?.presence
      where << "#{@@table}.cc_i16 = #{nqm.next}"
      bindings << cc_i16
    end
    pagination_before_after "requestlogs"

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
