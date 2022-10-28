@[Kpbb::Orm::Table(from: "discussion_links")]
struct Kpbb::DiscussionLink
  Kpbb::Util::Model.select
  # Kpbb::Util::Model.find_by_bigint_id
  # Kpbb::Util::Model.find_by_http_env("link_id")
  # Kpbb::Util::Model.base62_url("/links")
  @@table = "discussion_links"

  def self.select_columns : Array(String)
    ["link_id", "dlink_id"]
  end

  property link_id : Int64
  property dlink_id : Int64

  def initialize(
    @link_id : Int64,
    @dlink_id : Int64
  )
  end

  def initialize(rs : DB::ResultSet)
    @link_id = rs.read(Int64)
    @dlink_id = rs.read(Int64)
  end

  def self.save!(
    link_url : String,
    dlink_url : String
  ) : Nil
    self.save!(
      link_id: Kpbb::Link.save!(link_url),
      dlink_id: Kpbb::Link.save!(dlink_url)
    )
  end

  def self.save!(
    link_id : Int64,
    dlink_id : Int64
  ) : Nil
    raise "link cannot discuss itself" if link_id == dlink_id
    Kpbb.db.exec(<<-SQL,
      INSERT INTO discussion_links (link_id, dlink_id)
      VALUES ($1, $2) ON CONFLICT (link_id, dlink_id)
      DO NOTHING
    SQL
      args: [
        link_id,
        dlink_id,
      ])
  end

  def self.sync!(link_ids : Array(Int64)?) : Nil
    return if link_ids.try(&.size) == 0
    bindings = Array(Int64).new
    query = String.build do |query|
      query << <<-SQL
        UPDATE links SET discussions = (
          SELECT COUNT(*) FROM discussion_links
          WHERE discussion_links.link_id = links.id)
      SQL
      if link_ids
        query << "WHERE links.id IN ("
        query << link_ids.join(", ")
        query << ")"
      end
    end
    result : DB::ExecResult = Kpbb.db.exec(query, args: bindings)
    pp ({ "result.rows_affected" => result.rows_affected})
  end

  def self.all() : Array(self)
    query = "SELECT #{self.select} FROM #{@@table} ORDER BY link_id ASC, dlink_id ASC"
    list = Array(self).new

    Kpbb.db.query(query) do |rs|
      rs.each { list << self.new(rs) }
    end
    list
  end
end
