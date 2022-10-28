@[Kpbb::Orm::Table(from: "uploads")]
struct Kpbb::Upload
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("upload_id")
  @@table = "uploads"

  def self.select_columns : Array(String)
    ["id", "creator_id", "ip::TEXT as ip", "ua_id", "mime_id", "size", "width", "height", "crc32", "status", "filename", "typedesc", "created_at", "updated_at"]
  end

  property id : Int64
  property creator_id : Int64
  property ip : String?
  property ua_id : Int64?
  property mime_id : Int64?
  property size : Int64?
  property width : Int16?
  property height : Int16?
  property crc32 : Int64?
  property status : Kpbb::Upload::Status
  property filename : String?
  property typedesc : String?
  property created_at : Time
  property updated_at : Time

  def initialize(
    @id : Int64,
    @creator_id : Int64,
    @ip : String?,
    @ua_id : Int64,
    @mime_id : Int64?,
    @size : Int64?,
    @width : Int16?,
    @height : Int16?,
    @crc32 : Int64?,
    @status : Kpbb::Upload::Status = Kpbb::Upload::Status::Pending,
    @filename : String? = nil,
    @typedesc : String? = nil,
    @created_at : Time = Time.utc,
    @updated_at : Time = Time.utc
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @creator_id = rs.read(Int64)
    @ip = rs.read(String?)
    @ua_id = rs.read(Int64)
    @mime_id = rs.read(Int64?)
    @size = rs.read(Int64?)
    @width = rs.read(Int16?)
    @height = rs.read(Int16?)
    @crc32 = rs.read(Int64?)
    @status = Kpbb::Upload::Status.new(rs.read(Int16))
    @filename = rs.read(String?)
    @typedesc = rs.read(String?)
    @created_at = rs.read(Time)
    @updated_at = rs.read(Time)
  end

  def self.save!(
    creator_id : Int64,
    ip : String?,
    ua_id : Int64,
    mime_id : Int64?,
    size : Int64?,
    width : Int16?,
    height : Int16?,
    crc32 : Int64?,
    status : Kpbb::Upload::Status = Kpbb::Upload::Status::Pending,
    filename : String? = nil,
    typedesc : String? = nil,
    connection : DB::Connection? = nil
  ) : self
    connection ||= Kpbb.db
    query = <<-SQL
      INSERT INTO uploads (creator_id, ip, ua_id, mime_id, size, width, height, crc32, status, filename, typedesc, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
      returning id, created_at, updated_at
    SQL
    id, created_at, updated_at = connection.query_one(query, args: [
      creator_id,
      ip,
      ua_id,
      mime_id,
      size,
      width,
      height,
      crc32,
      status.value,
      filename.presence,
      typedesc.presence,
    ], as: {Int64, Time, Time})
    self.new(id, creator_id, ip, ua_id, mime_id, size, width, height, crc32, status, filename.presence, typedesc.presence, created_at, updated_at)
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM uploads "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    # if env.params.query.truthy?("draft") && env.session.userId?
    #   where << "uploads.creator_id = #{nqm.next}"
    #   where << "uploads.draft IS TRUE"
    #   bindings << env.session.userId
    # else
    #   where << "uploads.draft IS FALSE"
    # end

    # if channel_id = (env.params.url["channel_id"]? || env.params.query["channel_id"]?).try(&.to_i64_from_b62?)
    #   where << "uploads.channel_id = #{nqm.next}"
    #   bindings << channel_id
    # end

    # if creator_id = (env.params.url["user_id"]? || env.params.query["user_id"]?).try(&.to_i64_from_b62?)
    #   where << "uploads.creator_id = #{nqm.next}"
    #   bindings << creator_id
    # end

    # # guests may only see uploads of public channels
    # if env.session.userId?.nil?
    #   where << <<-SQL
    #     EXISTS (
    #       SELECT 1 FROM channels
    #       WHERE uploads.channel_id = channels.id
    #       AND channels.public IS TRUE
    #     )
    #   SQL
    # else
    #   where << <<-SQL
    #     EXISTS (
    #       SELECT 1 FROM channels
    #       WHERE uploads.channel_id = channels.id
    #       AND channels.public IS TRUE
    #       UNION ALL
    #       SELECT 1 FROM channelmemberships as cm
    #       WHERE cm.channel_id = uploads.channel_id
    #       AND cm.user_id = #{nqm.next}
    #     )
    #   SQL
    #   bindings << env.session.userId
    # end

    # if env.params.query.truthy?("saved") && env.session.userId?
    #   where << <<-SQL
    #     EXISTS (
    #       SELECT 1 from postusers
    #       WHERE postusers.upload_id = uploads.id
    #       AND postusers.user_id = #{nqm.next}
    #       AND postusers.saved IS TRUE
    #     )
    #   SQL
    #   bindings << env.session.userId
    # elsif env.params.query.truthy?("hidden") && env.session.userId?
    #   where << <<-SQL
    #     EXISTS (
    #       SELECT 1 from postusers
    #       WHERE postusers.upload_id = uploads.id
    #       AND postusers.user_id = #{nqm.next}
    #       AND postusers.hidden IS TRUE
    #     )
    #   SQL
    #   bindings << env.session.userId
    # elsif env.session.userId?
    #   # logged in default: listed and not hidden
    #   where << <<-SQL
    #     NOT EXISTS (
    #       SELECT 1 from postusers
    #       WHERE postusers.upload_id = uploads.id
    #       AND postusers.user_id = #{nqm.next}
    #       AND postusers.hidden IS TRUE
    #     )
    #   SQL
    #   bindings << env.session.userId
    # else
    #   # guest default: listed
    # end

    # domain : String? = env.params.query["domain"]?.presence
    # url : String? = env.params.query["url"]?.presence
    # if (url || domain)
    #   clause = "EXISTS (SELECT 1 FROM links WHERE "
    #   if domain
    #     clause += <<-SQL
    #       EXISTS (
    #         SELECT 1 FROM domains
    #         WHERE domain = #{nqm.next}
    #         AND links.domain_id = domains.id
    #       )
    #     SQL
    #     bindings << domain
    #   end
    #   if domain && url
    #     clause += " AND "
    #   end
    #   if url
    #     clause += " links.url = #{nqm.next} "
    #     bindings << url
    #   end
    #   clause += "AND links.id = uploads.link_id)"
    #   where << clause
    # end

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

enum Kpbb::Upload::Status : Int16
  Uploaded = 0 # uploaded to s3
  Pending  = 1 # pending processing and final validation
  Rejected = 2 # validation errors
  Error    = 3 # something crashed
end
