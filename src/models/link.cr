@[Kpbb::Orm::Table(from: "links")]
struct Kpbb::Link
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("link_id")
  Kpbb::Util::Model.base62_url("/links")
  @@table = "links"

  def self.select_columns : Array(String)
    ["id", "domain_id", "url", "url_abbr", "meta", "active", "discussions", "lastseen_at", "created_at", "updated_at"]
  end

  property id : Int64
  property domain_id : Int64
  property url : String
  # twitter.com/spacegazebo is cool, but can't be generated from url
  # for services like youtube. An optional url_abbr column will allow us to
  # make a seperate service to manually generate helpful values
  # like youtube/spacegazebo, despite that value not actually existing.
  property url_abbr : String?
  property meta : String?
  property active : Bool
  property discussions : Int16?
  property lastseen_at : Time
  property updated_at : Time
  property created_at : Time

  def has_discussions? : Bool
    discussions > 0_i16
  end

  def discussions : Int16
    @discussions || 0_i16
  end

  def initialize(
    @id : Int64,
    @domain_id : Int64,
    @url : String,
    @url_abbr : String? = nil,
    @meta : String? = nil,
    @active : Bool = true,
    @discussions : Int16? = nil,
    @lastseen_at : Time = Time.utc,
    @updated_at : Time = Time.utc,
    @created_at : Time = Time.utc
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @domain_id = rs.read(Int64)
    @url = rs.read(String)
    @url_abbr = rs.read(String?)
    meta = rs.read(JSON::Any?)
    @meta = meta.nil? ? nil : meta.to_json
    @active = rs.read(Bool)
    @discussions = rs.read(Int16?)
    @lastseen_at = rs.read(Time)
    @created_at = rs.read(Time)
    @updated_at = rs.read(Time)
  end

  def meta : Kpbb::Link::Meta
    if v = @meta
      Kpbb::Link::Meta.from_json v
    else
      Kpbb::Link::Meta.new
    end
  end

  def meta_s : String?
    @meta
  end

  def url_abbr : String?
    @url_abbr || ::Iom::UrlAbbr.url_abbr(@url)
  end

  def self.save!(
    url : String,
    domain_id : Int64,
    meta : String? = nil,
    # domain_id : Int64? = nil,
    active : Bool = true
  ) : Int64
    # domain_id ||= Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    id = Kpbb.db.query_one(<<-SQL,
      INSERT INTO links (domain_id, url, meta, active, lastseen_at, created_at, updated_at)
      VALUES ($1, $2, $3, $4, NOW(), NOW(), NOW())
      returning id
    SQL
      args: [
        domain_id,
        url,
        meta,
        active,
      ], as: Int64)
    Kpbb::Domain.update_lastseen_at(domain_id)
    id
  end

  def self.save!(url : String) : Int64
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    id = Kpbb.db.query_one(<<-SQL,
      INSERT INTO links (domain_id, url, active, lastseen_at, created_at, updated_at)
      VALUES ($1, $2, (
        SELECT domains.active FROM domains WHERE domains.id = $3
      ), NOW(), NOW(), NOW())
      ON CONFLICT (url) DO UPDATE SET lastseen_at = NOW()
      returning id
    SQL
      args: [
        domain_id,
        url,
        domain_id,
      ], as: Int64)
    Kpbb::Domain.update_lastseen_at(domain_id)
    id
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM links "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    where << "links.active IS TRUE"

    if domain_id = env.params.query["domain_id"]?.try(&.to_i64)
      where << "links.domain_id = " + nqm.next
      bindings << domain_id
    end

    q : String? = env.params.query["q"]?.try(&.strip).presence
    if q
      where << "url ILIKE #{nqm.next}"
      bindings << "%#{q}%"
    end

    meta : String? = env.params.query["meta"]?
    if meta == "null"
      where << "meta IS NULL"
    elsif meta == "notnull"
      where << "meta IS NOT NULL"
    elsif meta == "error"
      where << "((meta -> 'error') IS NOT NULL)"
    elsif meta == "file_extension"
      where << "((meta -> 'file_extension') IS NOT NULL)"
    elsif meta == "youtube"
      where << "((meta -> 'youtube') IS NOT NULL)"
    elsif meta == "unfurl"
      where << "((meta -> 'unfurl') IS NOT NULL)"
    elsif meta == "unknown"
      where << "((meta -> 'unknown') IS NOT NULL)"
    end

    # [
    #     true.to_s, #listed
    #     page.offset,
    # ]

    if where.size > 0
      query += "WHERE " + where.join(" AND ")
    end

    Page(self).new env do |page|
      query += " ORDER BY links.lastseen_at DESC"
      pagination_offset_limit
      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { page.collection << self.new(rs) }
      end
    end
  end

  def self.find(page : Page(Kpbb::Post)) : Array(self)
    list = Array(self).new

    link_id_list : Array(Int64) = page.collection.compact_map { |c| c.link_id }.uniq!
    if link_id_list.size > 0
      nqm = NextQuestionMark.new
      bindings : Array(Int64) = link_id_list
      query = <<-SQL
        SELECT #{self.select} FROM #{@@table}
        WHERE links.id IN (#{(link_id_list.map { |c| nqm.next }).join(", ")})
      SQL
      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { list << self.new(rs) }
      end
    end
    list
  end

  def self.fetch_recent(minute : Time) : Array(self)
    list = Array(self).new
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM links "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    where << "links.active IS TRUE"
    where << "links.meta IS NULL"
    where << "links.lastseen_at > CURRENT_DATE - INTERVAL '1 years'"
    where << <<-SQL
      EXISTS (
        SELECT 1 FROM domains
        WHERE links.domain_id = domains.id
        AND domains.active IS TRUE
      )
    SQL

    # where << "(links.created_at >= #{nqm.next} AND links.created_at <= #{nqm.next})"
    # bindings << minute
    # bindings << minute + 1.minute

    # if domain_id = env.params.query["domain_id"]?.try(&.to_i64)
    #   where << "links.domain_id = " + nqm.next
    #   bindings << domain_id
    # end

    if where.size > 0
      query += "WHERE " + where.join(" AND ")
    end

    query += " ORDER BY links.lastseen_at ASC"
    query += " LIMIT 5"
    Kpbb.db.query(query, args: bindings) do |rs|
      rs.each { list << self.new(rs) }
    end
    list
  end

  def self.fetch_discussions(link_id : Int64) : Array(self)
    list = Array(self).new
    query = <<-SQL
    SELECT #{self.select}
    FROM links
    WHERE links.active IS TRUE
    AND EXISTS (
      SELECT 1 FROM discussion_links
      WHERE discussion_links.link_id = $1
      AND discussion_links.link_id = links.id
    )
    AND EXISTS (
      SELECT 1 FROM domains
      WHERE links.domain_id = domains.id
      AND domains.active IS TRUE
    )
    SQL
    # bindings = Array(::Kpbb::PGValue).new
    bindings = [link_id]

    Kpbb.db.query(query, args: bindings) do |rs|
      rs.each { list << self.new(rs) }
    end
    list
  end

  def self.sync_discussion_count(link_id : Int64 | Array(Int64) | Nil)
    query = IO::Memory.new
    query << <<-SQL
    UPDATE links SET discussions = (
      SELECT COUNT(*) FROM discussion_links
      JOIN links dlinks ON discussion_links.dlink_id = dlinks.id
      WHERE discussion_links.link_id = links.id
      AND dlinks.active IS TRUE
      AND EXISTS (
        SELECT 1 FROM domains
        WHERE dlinks.domain_id = domains.id
        AND domains.active IS TRUE
      )
    )
    SQL

    case link_id
    when Int64
      query << "WHERE links.id = #{link_id}"
    when Array(Int64)
      if link_id.size > 0
        query << "WHERE links.id IN #{link_id.implode(", ")}"
      else
        return #nothing to update
      end
    else
      # do all
    end

    Kpbb.db.execute(query)
  end
end
