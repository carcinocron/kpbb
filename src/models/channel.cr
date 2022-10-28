@[Kpbb::Orm::Table(from: "channels")]
struct Kpbb::Channel
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("channel_id")
  Kpbb::Util::Model.find_by_http_env_string(handle)
  Kpbb::Util::Model.find_by_string_key(handle)
  Kpbb::Util::Model.handle_url("/channels")
  @@table = "channels"

  @[Kpbb::Orm::Column(insert: false, insert_return: true)]
  property id : Int64
  @[Kpbb::Orm::Column]
  property handle : String
  @[Kpbb::Orm::Column]
  property dname : String
  @[Kpbb::Orm::Column]
  str_getter bio
  @[Kpbb::Orm::Column]
  str_getter avatar
  @[Kpbb::Orm::Column]
  str_getter banner
  @[Kpbb::Orm::Column]
  property public : Bool
  @[Kpbb::Orm::Column]
  property listed : Bool
  @[Kpbb::Orm::Column]
  property creator_id : Int64
  @[Kpbb::Orm::Column(insert: "NOW()", insert_return: true)]
  property created_at : Time? = nil
  @[Kpbb::Orm::Column(insert: "NOW()", insert_return: true)]
  property updated_at : Time? = nil

  def initialize(
    @id : Int64,
    @handle : String,
    @dname : String,
    @bio : String?,
    @avatar : String?,
    @banner : String?,
    @public : Bool,
    @listed : Bool,
    @creator_id : Int64,
    @created_at : Time? = nil,
    @updated_at : Time? = nil
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @handle = rs.read(String)
    @dname = rs.read(String)
    @bio = rs.read(typeof(@bio))
    @avatar = rs.read((String | Nil))
    @banner = rs.read((String | Nil))
    @public = rs.read(Bool)
    @listed = rs.read(Bool)
    @creator_id = rs.read(Int64)
    @created_at = rs.read(Time?)
    @updated_at = rs.read(Time?)
    # define_init_from_rs
  end

  use_orm

  def self.fetch_page(env) : Page(self)
    q = Kpbb::Orm::Query.new
    q << "SELECT #{self.select} FROM #{@@table} "
    user_id = env.session.userId?
    if user_id
      q << "LEFT JOIN (SELECT * FROM channelmemberships WHERE user_id = #{q.bind(user_id)}) cms ON cms.channel_id = #{@@table}.id "
    end

    if env.params.query.truthy?("following") && user_id
      q.where "cms.follow IS TRUE"
    elsif env.params.query.truthy?("ranked") && user_id
      q.where "cms.rank > 0"
    elsif env.params.query.truthy?("hidden") && user_id
      q.where "cms.hidden_at IS NOT NULL"
    elsif user_id
      # logged in default: listed and not hidden
      q.where "cms.hidden_at IS NULL"
      q.where "#{@@table}.listed IS TRUE"
    else
      # guest default: listed
      q.where "#{@@table}.listed IS TRUE"
    end
    q.pagination_before_after env, "channels"

    page = Page(self).new env do |page|
      q.pagination_offset_limit(page)
      Kpbb.db.query(q.query.to_s, args: q.bindings) do |rs|
        rs.each { page.collection << self.init_from_rs(rs) }
      end
    end
  end

  def self.find_for_post_reply(env : HTTP::Server::Context) : Array(self)
    find_for_post_create env
  end

  def self.find_for_post_create(env : HTTP::Server::Context) : Array(self)
    list = Array(self).new
    bindings = [env.session.userId]
    query = <<-SQL
    SELECT #{self.select} FROM #{@@table}
    JOIN channelmemberships ON channelmemberships.channel_id = channels.id
    WHERE channelmemberships.user_id = $1
    AND channelmemberships.banned IS FALSE
    ORDER BY channelmemberships.hidden_at IS NOT NULL ASC, channelmemberships.follow DESC, channelmemberships.rank DESC
    LIMIT 50;
    SQL

    Kpbb.db.query(query, args: bindings) do |rs|
      rs.each { list << self.init_from_rs(rs) }
    end
    list
  end

  def self.find(page : Page(Kpbb::Post)) : Array(self)
    list = Array(self).new
    if page.collection.size > 0
      nqm = NextQuestionMark.new
      bindings : Array(Int64) = page.collection.map { |c| c.channel_id }
      query = <<-SQL
        SELECT #{self.select} FROM #{@@table}
        WHERE channels.id IN (#{(page.collection.map { |c| nqm.next }).join(", ")})
      SQL
      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { list << self.init_from_rs(rs) }
      end
    end
    list
  end
end
