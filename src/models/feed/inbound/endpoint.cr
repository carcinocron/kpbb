@[Kpbb::Orm::Table(from: "feed_inbound_endpoints")]
struct Kpbb::Feed::Inbound::Endpoint
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("endpoint_id")
  @@table = "feed_inbound_endpoints"

  def self.select_columns : Array(String)
    ["id", "creator_id", "channel_id", "url", "bio", "data",
     "default_body",
     "active", "mask", "frequency",
     "lastpolled_at", "nextpoll_at", "lastposted_at", "nextpost_at",
     "created_at", "updated_at"]
  end

  property id : Int64
  property creator_id : Int64
  property channel_id : Int64
  property url : String
  property bio : String?
  property data : String?
  @default_body : String?
  property active : Bool
  property mask : Kpbb::Mask::Mask
  property frequency : Int16
  property lastpolled_at : Time?
  property nextpoll_at : Time?
  property lastposted_at : Time?
  property nextpost_at : Time?
  property created_at : Time
  property updated_at : Time

  def mask : Kpbb::Mask::Mask
    @mask
  end

  def data : Kpbb::Feed::Inbound::Endpoint::Data
    if v = @data
      Kpbb::Feed::Inbound::Endpoint::Data.from_json v
    else
      Kpbb::Feed::Inbound::Endpoint::Data.new
    end
  end

  def data_s : String?
    @data
  end

  include Kpbb::Concern::HasDefaultBody

  def frequency_days : Int
    (Time.utc - @created_at).total_days.floor.clamp(1, 90)
  end

  def initialize(
    @id : Int64,
    @creator_id : Int64,
    @channel_id : Int64,
    @url : String,
    @bio : String?,
    @data : String?,
    @default_body : String?,
    @active : Bool,
    @mask : Kpbb::Mask::Mask,
    @frequency : Int16,
    @lastpolled_at : Time?,
    @nextpoll_at : Time?,
    @lastposted_at : Time?,
    @nextpost_at : Time?,
    @created_at : Time,
    @updated_at : Time
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(typeof(@id))
    @creator_id = rs.read(Int64)
    @channel_id = rs.read(Int64)
    @url = rs.read(String)
    @bio = rs.read(typeof(@bio))
    data = rs.read(JSON::Any?)
    @data = data.nil? ? nil : data.to_json
    default_body = rs.read(JSON::Any?)
    @default_body = default_body.nil? ? nil : default_body.to_json
    @active = rs.read(Bool)
    @mask = Kpbb::Mask::Mask.parse_from_db(rs.read(Int16?))
    @frequency = rs.read(Int16)
    @lastpolled_at = rs.read(Time?)
    @nextpoll_at = rs.read(Time?)
    @lastposted_at = rs.read(Time?)
    @nextpost_at = rs.read(Time?)
    @created_at = rs.read(Time)
    @updated_at = rs.read(Time)
  end

  def verify(value) : Bool
    hashed_url = Crypto::Bcrypt::Password.new(self.url)
    hashed_url.verify(value)
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    channel_id = (env.params.url["channel_id"]? || env.params.query["channel_id"]?).try(&.to_i64_from_b62?)
    if channel_id
      where << "feed_inbound_endpoints.channel_id = #{nqm.next}"
      bindings << channel_id
    end

    if env.params.query.falsey?("active") && env.session.userId?
      where << "feed_inbound_endpoints.active IS FALSE"
    else
      where << "feed_inbound_endpoints.active IS TRUE"
    end

    pagination_before_after "feed_inbound_endpoints"
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

  def update_lastpolled_at
    query = <<-SQL
      UPDATE feed_inbound_endpoints
      SET lastpolled_at = NOW()
      WHERE id = $1
    SQL
    Kpbb.db.exec query, args: [@id]
  end

  def update_lastpollposted_at
    query = <<-SQL
      UPDATE feed_inbound_endpoints
      SET lastposted_at = NOW()
      WHERE id = $1
    SQL
    Kpbb.db.exec query, args: [@id]
  end

  # logic accept up to one brand new one,
  # then up to 5 unpolled ones
  # @todo add "frequency" logic
  def self.fetch_for_cron(minute : Time) : Array(self)
    list = Array(self).new
    sel = self.select(prefix: "endpoints")
    query = <<-SQL
      SELECT #{sel}
      FROM (
        SELECT DISTINCT ON (channel_id) #{sel}
        FROM ( (
            SELECT #{sel}
            FROM #{@@table} as endpoints
            WHERE nextpoll_at IS NULL
            ORDER BY id ASC
            LIMIT 1
          ) UNION ALL (
            SELECT #{sel}
            FROM #{@@table} as endpoints
            WHERE nextpoll_at IS NOT NULL
            AND (lastpolled_at < $1 OR lastpolled_at IS NULL)
            ORDER BY nextpoll_at ASC
            LIMIT 5
        ) ) as endpoints
      ) as endpoints
      ORDER BY (nextpoll_at IS NULL) DESC, nextpoll_at ASC
      LIMIT 5
    SQL
    bindings = [
      minute - 1.hour, # never poll anything more often than once per hour
    ]
    Kpbb.db.query(query, args: bindings) do |rs|
      rs.each { list << self.new(rs) }
    end
    list
  end
end
