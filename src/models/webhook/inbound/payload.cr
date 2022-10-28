module Kpbb::Webhook::Inbound
  enum PayloadPath : Int16
    Posts = 1

    def self.parse(input : String?) : self?
      return PayloadPath::Posts if input == "posts"
      nil
    end
  end

  struct Payload
    Kpbb::Util::Model.select
    Kpbb::Util::Model.find_by_bigint_id
    Kpbb::Util::Model.find_by_http_env("payload_id")
    include Iom::CountryCode::HasCountryCodeNaturalKey
    @@table = "webhook_inbound_payloads"

    def self.select_columns : Array(String)
      ["id", "channel_id", "endpoint_id", "cc_i16", "ip::TEXT as ip", "path",
       "data", "result", "created_at", "updated_at"]
    end

    property id : Int64
    property channel_id : Int64
    property endpoint_id : Int64
    property cc_i16 : Int16
    property ip : String?
    property path : PayloadPath
    property data : String?
    property result : String?
    property created_at : Time
    property updated_at : Time

    def initialize(
      @id : Int64,
      @channel_id : Int64,
      @endpoint_id : Int64,
      @cc_i16 : Int16,
      @ip : String?,
      @path : PayloadPath,
      @data : String?,
      @result : String?,
      @created_at : Time,
      @updated_at : Time
    )
    end

    def initialize(rs : DB::ResultSet)
      @id = rs.read(Int64)
      @channel_id = rs.read(Int64)
      @endpoint_id = rs.read(Int64)
      @cc_i16 = rs.read(Int16?) || 0_i16
      @ip = rs.read(String?)
      path_id = rs.read(Int16)
      @path = PayloadPath.new(path_id.to_i16)
      data = rs.read(JSON::Any?)
      @data = data.nil? ? nil : data.to_json
      result = rs.read(JSON::Any?)
      @result = result.nil? ? nil : result.to_json
      @created_at = rs.read(Time)
      @updated_at = rs.read(Time)
    end

    def data : Payload::Data
      if v = @data
        Payload::Data.from_json v
      else
        Payload::Data.new
      end
    end

    def data_s : String?
      @data
    end

    def result : Payload::Result
      if v = @result
        Payload::Result.from_json v
      else
        Payload::Result.new
      end
    end

    def result_s : String?
      @result
    end

    def self.save!(
      endpoint_id : Int64,
      cc_i16 : Int16,
      ip : String?,
      path : String,
      data : String?,
      result : String? = nil
    ) : self
      self.save!(
        endpoint_id,
        PayloadPath.parse(path).not_nil!,
        data, result)
    end

    def self.save!(
      endpoint_id : Int64,
      cc_i16 : Int16,
      ip : String?,
      path : PayloadPath,
      data : String?,
      result : String? = nil
    ) : self
      query = <<-SQL
        INSERT INTO #{@@table} (
          channel_id,
          endpoint_id, cc_i16, ip,
          path, data, result,
          created_at, updated_at)
        VALUES (
          (SELECT channel_id FROM webhook_inbound_endpoints
            WHERE id = $1),
          $2, $3, $4,
          $5, $6, $7,
          NOW(), NOW())
        returning id, channel_id, created_at, updated_at
      SQL
      id, channel_id, created_at, updated_at = Kpbb.db.query_one(query, args: [
        endpoint_id,
        endpoint_id,
        cc_i16,
        ip,
        path.value,
        data.presence,
        result.presence,
      ], as: {Int64, Int64, Time, Time})
      self.new(id, channel_id, endpoint_id, cc_i16, ip, path,
        data, result, created_at, updated_at)
    end

    def self.fetch_page(env) : Page(self)
      nqm = NextQuestionMark.new
      query = "SELECT #{self.select} FROM #{@@table} "
      bindings = Array(::Kpbb::PGValue).new
      where = Array(String).new

      channel_id = (env.params.url["channel_id"]? || env.params.query["channel_id"]?).try(&.to_i64_from_b62?)
      if channel_id
        where << "webhook_inbound_payloads.channel_id = #{nqm.next}"
        bindings << channel_id
      end
      endpoint_id = (env.params.url["endpoint_id"]? || env.params.query["endpoint_id"]?).try(&.to_i64_from_b62?)
      if endpoint_id
        where << "webhook_inbound_payloads.endpoint_id = #{nqm.next}"
        bindings << endpoint_id
      end
      result = env.params.query["result"]?
      if result == "null"
        where << "result IS NULL"
      elsif result == "notnull"
        where << "result IS NOT NULL"
      end

      pagination_before_after "webhook_inbound_payloads"
      if where.size > 0
        query += "WHERE " + where.join(" AND ")
      end

      query += " ORDER BY id DESC"

      page = Page(self).new env do |page|
        pagination_offset_limit
        Kpbb.db.query(query, args: bindings) do |rs|
          rs.each { page.collection << self.new(rs) }
        end
      end
    end

    def self.all : Array(self)
      query = "SELECT #{self.select} FROM #{@@table} ORDER BY id ASC"
      list = Array(self).new

      Kpbb.db.query(query) do |rs|
        rs.each { list << self.new(rs) }
      end
      list
    end

    # we'll get only one per endpoint
    # to prevent things from moving too fast
    def self.fetch_one_per_endpoint(minute : Time) : Array(self)
      sel = self.select(prefix: "payloads")
      query = <<-SQL
        SELECT DISTINCT ON (channel_id) #{sel}
        FROM (
          SELECT #{sel}
          FROM #{@@table} as payloads
          JOIN webhook_inbound_endpoints as endpoints ON endpoints.id = payloads.endpoint_id
          WHERE payloads.result IS NULL
          AND payloads.created_at <= $1
          AND (endpoints.nextpost_at IS NULL OR NOW() > endpoints.nextpost_at)
          ORDER BY payloads.id ASC
        ) as payloads
        LIMIT 25
      SQL
      bindings = [minute]
      list = Array(self).new

      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { list << self.new(rs) }
      end
      list
    end
  end
end
