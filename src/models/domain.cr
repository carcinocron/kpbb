@[Kpbb::Orm::Table(from: "domains")]
struct Kpbb::Domain
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_string_key(value)
  Kpbb::Util::Model.find_by_http_env("domain_id")
  Kpbb::Util::Model.base62_url("/domains")
  @@table = "domains"

  def self.select_columns : Array(String)
    ["id", "domain", "active", "lastseen_at", "updated_at", "created_at"]
  end

  @[Kpbb::Orm::Column(insert: false, insert_return: true)]
  property id : Int64
  property domain : String
  property active : Bool
  property lastseen_at : Time
  property updated_at : Time
  property created_at : Time

  def initialize(
    @id : Int64,
    @domain : String,
    @active : Bool = true,
    @lastseen_at : Time = Time.utc,
    @updated_at : Time = Time.utc,
    @created_at : Time = Time.utc
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @domain = rs.read(String)
    @active = rs.read(Bool)
    @lastseen_at = rs.read(Time)
    @created_at = rs.read(Time)
    @updated_at = rs.read(Time)
  end

  def self.save!(
    domain : String,
    active : Bool
  ) : Int64
    query = <<-SQL
      INSERT INTO #{@@table} (domain, active, lastseen_at, created_at, updated_at)
      VALUES ($1, $2, NOW(), NOW(), NOW())
      ON CONFLICT (domain) DO UPDATE
      SET active = excluded.active
      returning id
    SQL
    id = Kpbb.db.query_one(query, args: [
      domain,
      active,
    ], as: Int64)
    id
  end

  def self.save!(domain : String) : Int64
    query = <<-SQL
      INSERT INTO #{@@table} (domain, active, lastseen_at, created_at, updated_at)
      VALUES ($1, true, NOW(), NOW(), NOW())
      ON CONFLICT (domain) DO UPDATE
      SET lastseen_at = NOW()
      returning id
    SQL
    id = Kpbb.db.query_one(query, args: [
      domain,
    ], as: Int64)
    id
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    where << "#{@@table}.active IS TRUE"

    q : String? = env.params.query["q"]?.try(&.strip).try(&.presence)
    if q
      where << ("#{@@table}.domain LIKE #{nqm.next}")
      bindings << "%#{q}%"
    end

    # [
    #     true.to_s, #listed
    #     page.offset,
    # ]

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

  def self.find_by_link?(link : Kpbb::Link?) : self?
    return nil if link.nil?
    self.find? link.domain_id
  end

  def self.update_lastseen_at(domain_id : Int64)
    Kpbb.db.exec(<<-SQL,
      UPDATE #{@@table} SET lastseen_at = (
        SELECT MAX(lastseen_at) FROM links WHERE links.domain_id = #{@@table}.id
      ) WHERE #{@@table}.id = $1
    SQL


      args: [domain_id])
  end
end
