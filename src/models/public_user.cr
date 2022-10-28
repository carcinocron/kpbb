@[Kpbb::Orm::Table(from: "users")]
struct Kpbb::PublicUser
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("user_id")
  Kpbb::Util::Model.find_by_string_key(handle)
  Kpbb::Util::Model.handle_url("/users")
  @@table = "users"

  def self.select_columns : Array(String)
    ["id", "handle", "dname", "bio", "pronouns", "avatar", "banner"]
  end

  @[Kpbb::Orm::Column]
  property id : Int64
  @[Kpbb::Orm::Column]
  property handle : String
  @[Kpbb::Orm::Column]
  property dname : String
  @[Kpbb::Orm::Column]
  property bio : String?
  @[Kpbb::Orm::Column]
  str_getter avatar
  @[Kpbb::Orm::Column]
  str_getter banner
  @[Kpbb::Orm::Column]
  str_getter pronouns

  def initialize(
    @id : Int64,
    @handle : String,
    @dname : String,
    @bio : String?,
    @pronouns : String?,
    @avatar : String?,
    @banner : String?
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @handle = rs.read(typeof(@handle))
    @dname = rs.read(String)
    @bio = rs.read(typeof(@bio))
    @pronouns = rs.read(typeof(@pronouns))
    @avatar = rs.read(typeof(@avatar))
    @banner = rs.read(typeof(@banner))
  end

  use_orm

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    user_id = env.session.userId?

    if env.session.admin?
      if env.params.query.truthy?("ranked") && user_id
        where << "users.rank > 0"
      end
    end

    pagination_before_after "users"

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
end
