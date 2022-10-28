@[Kpbb::Orm::Table(from: "tags")]
struct Kpbb::Tag
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_string_key(value)
  Kpbb::Util::Model.find_by_http_env_string(value)
  Kpbb::Util::Model.base62_url("/tags")
  @@table = "tags"

  def self.select_columns : Array(String)
    ["id", "value", "active", "lastseen_at", "created_at"]
  end

  property id : Int64
  property value : String
  property active : Bool
  property lastseen_at : Time
  property created_at : Time

  def initialize(
    @id : Int64,
    @value : String,
    @active : Bool = true,
    @lastseen_at : Time = Time.utc,
    @created_at : Time = Time.utc
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @value = rs.read(String)
    @active = rs.read(Bool)
    @lastseen_at = rs.read(Time)
    @created_at = rs.read(Time)
  end

  def self.save!(
    value : String,
    active : Bool
  ) : self
    id, value, active, lastseen_at, created_at = Kpbb.db.query_one(<<-SQL,
      INSERT INTO #{@@table} (value, active, lastseen_at, created_at)
      VALUES ($1, $2, NOW(), NOW())
      ON CONFLICT (value) DO UPDATE
      SET active = excluded.active
      returning #{self.select}
    SQL


      args: [
        value,
        active,
      ], as: {Int64, String, Bool, Time, Time})
    self.new(id, value, active, lastseen_at, created_at)
  end

  def self.save!(value : String) : self
    id, value, active, lastseen_at, created_at = Kpbb.db.query_one(<<-SQL,
      INSERT INTO #{@@table} (value, active, lastseen_at, created_at)
      VALUES ($1, true, NOW(), NOW())
      ON CONFLICT (value) DO UPDATE
      SET lastseen_at = NOW()
      returning #{self.select}
    SQL


      args: [
        value,
      ], as: {Int64, String, Bool, Time, Time})
    self.new(id, value, active, lastseen_at, created_at)
  end

  def self.upsert!(values : Array(String)) : Array(self)
    list = Array(self).new
    if values.size > 0
      nqm = NextQuestionMark.new
      bindings = Array(::Kpbb::PGValue).new
      values.each { |v| bindings << v }
      query = <<-SQL
        INSERT INTO #{@@table} (value, active, lastseen_at, created_at)
        VALUES (#{values.map { "#{nqm.next}, true, NOW(), NOW()" }.join("),(")})
        ON CONFLICT (value) DO UPDATE
        SET lastseen_at = excluded.lastseen_at
        returning #{self.select}
      SQL
      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { list << self.new(rs) }
      end
    end
    list
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    where << "#{@@table}.active IS TRUE"

    q : String? = env.params.query["q"]?
    if q && !q.not_nil!.blank?
      where << ("#{@@table}.value LIKE #{nqm.next}")
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

  def self.update_lastseen_at(tag_id : Int64)
    Kpbb.db.exec(<<-SQL,
      UPDATE #{@@table} SET lastseen_at = NOW() WHERE #{@@table}.id = $1
    SQL


      args: [tag_id])
  end

  def self.parse(value : String) : String?
    Iom::WebSlug.slug(value)
  end

  def self.parse(value : Nil) : Nil
    nil
  end

  def self.parse(list : Array(String | Nil)) : Array(String)
    list.compact_map { |s| Iom::WebSlug.slug(s).presence }.uniq!
  end

  def self.sync!(post, connection : DB::Connection? = nil) : Nil
    connection ||= Kpbb.db
    post_id = post.id.not_nil!
    slugs : Array(String) = self.parse((post.tags || "").split(","))
    tags = self.upsert!(slugs).select!(&.active)

    if tags.size > 0
      nqm = NextQuestionMark.new
      query = <<-SQL
        INSERT INTO post_tag (post_id, tag_id)
        VALUES (#{tags.map { "#{nqm.next}, #{nqm.next}" }.join("), (")})
        ON CONFLICT (post_id, tag_id) DO NOTHING
      SQL
      bindings = Array(Int64).new
      tags.each do |tag|
        bindings << post_id
        bindings << tag.id
      end
      connection.exec(query, args: bindings)
    end

    nqm = NextQuestionMark.new
    query = <<-SQL
      DELETE FROM post_tag
      WHERE post_id = #{nqm.next}
    SQL

    bindings = Array(Int64).new
    bindings << post_id
    if tags.size > 0
      query += " AND tag_id NOT IN (#{tags.map { nqm.next }.join(", ")})"
      tags.each do |t|
        bindings << t.id
      end
    end

    connection.exec(query, args: bindings)
  end
end
