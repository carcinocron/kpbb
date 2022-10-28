require "uuid"

struct Kpbb::Webhook::Inbound::Endpoint
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("endpoint_id")
  Kpbb::Util::Model.find_by_uuid
  @@table = "webhook_inbound_endpoints"

  def self.select_columns : Array(String)
    ["id", "creator_id", "channel_id", "uuid", "secret", "bio", "data",
     "default_body",
     "active", "mask",
     "lastactive_at", "lastposted_at", "nextpost_at",
     "created_at", "updated_at"]
  end

  property id : Int64
  property creator_id : Int64
  property channel_id : Int64
  property uuid : UUID
  property secret : String
  property bio : String?
  property data : String?
  @default_body : String?
  property active : Bool
  property mask : Kpbb::Mask::Mask
  property lastactive_at : Time?
  property lastposted_at : Time?
  property nextpost_at : Time?
  property created_at : Time
  property updated_at : Time

  def data : Kpbb::Webhook::Inbound::Endpoint::Data
    if v = @data
      Kpbb::Webhook::Inbound::Endpoint::Data.from_json v
    else
      Kpbb::Webhook::Inbound::Endpoint::Data.new
    end
  end

  def data_s : String?
    @data
  end

  include Kpbb::Concern::HasDefaultBody

  def initialize(
    @id : Int64,
    @creator_id : Int64,
    @channel_id : Int64,
    @uuid : UUID,
    @secret : String,
    @bio : String?,
    @data : String?,
    @default_body : String?,
    @active : Bool,
    @mask : Kpbb::Mask::Mask,
    @lastactive_at : Time?,
    @lastposted_at : Time?,
    @nextpost_at : Time?,
    @created_at : Time,
    @updated_at : Time
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @creator_id = rs.read(Int64)
    @channel_id = rs.read(Int64)
    uuid = rs.read(String)
    @uuid = UUID.new uuid
    @secret = rs.read(String)
    @bio = rs.read(typeof(@bio))
    data = rs.read(JSON::Any?)
    @data = data.nil? ? nil : data.to_json
    default_body = rs.read(JSON::Any?)
    @default_body = default_body.nil? ? nil : default_body.to_json
    @active = rs.read(Bool)
    @mask = Kpbb::Mask::Mask.parse_from_db(rs.read(Int16?))
    @lastactive_at = rs.read(Time?)
    @lastposted_at = rs.read(Time?)
    @nextpost_at = rs.read(Time?)
    @created_at = rs.read(Time)
    @updated_at = rs.read(Time)
  end

  def uuid_s : String
    self.uuid.to_s.gsub("-", "")
  end

  def verify(value) : Bool
    hashed_secret = Crypto::Bcrypt::Password.new(self.secret)
    hashed_secret.verify(value)
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    channel_id = (env.params.url["channel_id"]? || env.params.query["channel_id"]?).try(&.to_i64_from_b62?)
    if channel_id
      where << "webhook_inbound_endpoints.channel_id = #{nqm.next}"
      bindings << channel_id
    end

    if env.params.query.falsey?("active") && env.session.userId?
      where << "webhook_inbound_endpoints.active IS FALSE"
    else
      where << "webhook_inbound_endpoints.active IS TRUE"
    end

    pagination_before_after "webhook_inbound_endpoints"
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

  def update_lastactive_at
    query = <<-SQL
      UPDATE webhook_inbound_endpoints
      SET lastactive_at = NOW()
      WHERE id = $1
    SQL
    Kpbb.db.exec query, args: [@id]
  end
end
