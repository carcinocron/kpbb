@[Kpbb::Orm::Table(from: "posts")]
struct Kpbb::Post
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("post_id")
  Kpbb::Util::Model.base62_url("/posts")
  Kpbb::Util::Model.base62_title_url("/posts")
  include Iom::CountryCode::HasCountryCodeNaturalKey
  # include Kpbb::Mask::HasMask
  @@table = "posts"

  def self.select_columns : Array(String)
    ["id", "channel_id", "parent_id", "creator_id",
     "title", "tags", "url", "link_id", "body_md", "body_html",
     "score", "dreplies", "treplies", "mask", "cc_i16", "ip::TEXT as ip",
     "posted", "locked", "dead", "draft",
     "published_at", "ptype", "created_at", "updated_at"]
  end

  property id : Int64
  property channel_id : Int64
  property parent_id : Int64?
  property creator_id : Int64?
  property title : String?
  property tags : String?
  property url : String?
  property link_id : Int64?
  property body_md : String?
  property body_html : String?
  property score : Int32
  # direct replies
  property dreplies : Int16
  # thread replies
  property treplies : Int16
  property mask : Kpbb::Mask::Mask
  property cc_i16 : Int16
  property ip : String?
  property posted : Bool
  property locked : Bool
  property dead : Bool
  property draft : Bool
  property updated_at : Time
  property created_at : Time
  property published_at : Time?
  property ptype : Kpbb::Post::Type

  def initialize(
    @id : Int64,
    @channel_id : Int64,
    @parent_id : Int64?,
    @creator_id : Int64,
    @title : String? = nil,
    @tags : String? = nil,
    @url : String? = nil,
    @link_id : Int64? = nil,
    @body_md : String? = nil,
    @body_html : String? = nil,
    @score : Int32 = 0,
    @dreplies : Int16 = 0_i16,
    @treplies : Int16 = 0_i16,
    @mask : Kpbb::Mask::Mask = Kpbb::Mask::Mask::None,
    @cc_i16 : Int16 = 0_i16,
    @ip : String? = nil,
    @posted : Bool = true,
    @locked : Bool = true,
    @dead : Bool = true,
    @draft : Bool = true,
    @published_at : Time? = nil,
    @ptype : Kpbb::Post::Type = Kpbb::Post::Type::None,
    @updated_at : Time = Time.utc,
    @created_at : Time = Time.utc
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @channel_id = rs.read(Int64)
    @parent_id = rs.read(Int64?)
    @creator_id = rs.read(Int64)
    @title = rs.read(String?)
    @tags = rs.read(String?)
    @url = rs.read(String?)
    @link_id = rs.read(Int64?)
    @body_md = rs.read(String?)
    @body_html = rs.read(String?)
    @score = rs.read(Int32?) || 0_i32
    @dreplies = rs.read(Int16?) || 0_i16
    @treplies = rs.read(Int16?) || 0_i16
    @mask = Kpbb::Mask::Mask.parse_from_db(rs.read(Int16?))
    @cc_i16 = rs.read(Int16?) || 0_i16
    @ip = rs.read(String?)
    @posted = rs.read(Bool)
    @locked = rs.read(Bool)
    @dead = rs.read(Bool)
    @draft = rs.read(Bool)
    @published_at = rs.read(Time?)
    @ptype = Kpbb::Post::Type.parse_from_db(ptype_i = rs.read(Int16?))
    @created_at = rs.read(Time)
    @updated_at = rs.read(Time)
  end

  def self.save!(
    channel_id : Int64,
    parent_id : Int64?,
    creator_id : Int64,
    title : String?,
    tags : String?,
    url : String?,
    link_id : Int64?,
    body_md : String?,
    body_html : String?,
    score : Int32,
    dreplies : Int16,
    treplies : Int16,
    mask : Kpbb::Mask::Mask,
    cc_i16 : Int16,
    ip : String?,
    posted : Bool,
    locked : Bool,
    dead : Bool,
    draft : Bool,
    published_at : Time? = nil,
    ptype : Kpbb::Post::Type = Kpbb::Post::Type::None
  ) : Int64
    id = Kpbb.db.query_one(<<-SQL,
      INSERT INTO posts (
        channel_id, parent_id, creator_id,
        title, tags, url, link_id,
        body_md, body_html,
        score, dreplies, treplies, mask, cc_i16, ip,
        posted, locked, dead, draft,
        published_at, ptype, created_at, updated_at)
      VALUES (
        $1, $2, $3,
        $4, $5, $6, $7,
        $8, $9,
        $10, $11, $12, $13, ($14)::INET,
        $15, $16, $17, $18,
        $19, NOW(), NOW())
      returning id
    SQL
      args: [
        channel_id,
        parent_id,
        creator_id,
        title,
        tags,
        url,
        link_id,
        body_md,
        body_html,
        score,
        dreplies,
        treplies,
        mask.to_db_value,
        cc_i16,
        ip,
        posted,
        locked,
        dead,
        draft,
        published_at,
        ptype.to_db_value,
      ], as: Int64)
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM posts "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    if env.params.query.truthy?("draft") && env.session.userId?
      where << "posts.creator_id = #{nqm.next}"
      where << "posts.draft IS TRUE"
      bindings << env.session.userId
    else
      where << "posts.draft IS FALSE"
    end

    if ptype = Kpbb::Post::Type.parse_from_input(env.params.query["ptype"]?)
      if ptype == Kpbb::Post::Type::None
        where << "posts.ptype IS NULL"
      else
        where << "posts.ptype = #{ptype.value}"
      end
    end
    # @todo from_b62
    # if parent_id = env.params.query["parent_id"]?.try(&.to_i64?)
    #   if parent_id == 0
    #     where << "posts.parent_id IS NULL"
    #   else
    #     where << "posts.parent_id = #{nqm.next}"
    #     bindings << parent_id
    #   end
    # end

    if channel_id = (env.params.url["channel_id"]? || env.params.query["channel_id"]?).try(&.to_i64_from_b62?)
      where << "posts.channel_id = #{nqm.next}"
      bindings << channel_id
    end

    if creator_id = (env.params.url["user_id"]? || env.params.query["user_id"]?).try(&.to_i64_from_b62?)
      where << "posts.creator_id = #{nqm.next}"
      bindings << creator_id
    end

    # guests may only see posts of public channels
    if env.session.userId?.nil?
      where << <<-SQL
        EXISTS (
          SELECT 1 FROM channels
          WHERE posts.channel_id = channels.id
          AND channels.public IS TRUE
        )
      SQL
    else
      where << <<-SQL
        EXISTS (
          SELECT 1 FROM channels
          WHERE posts.channel_id = channels.id
          AND channels.public IS TRUE
          UNION ALL
          SELECT 1 FROM channelmemberships as cm
          WHERE cm.channel_id = posts.channel_id
          AND cm.user_id = #{nqm.next}
        )
      SQL
      bindings << env.session.userId
    end

    if env.params.query.truthy?("saved") && env.session.userId?
      where << <<-SQL
        EXISTS (
          SELECT 1 from postusers
          WHERE postusers.post_id = posts.id
          AND postusers.user_id = #{nqm.next}
          AND postusers.saved_at IS NOT NULL
        )
      SQL
      bindings << env.session.userId
    elsif env.params.query.truthy?("hidden") && env.session.userId?
      where << <<-SQL
        EXISTS (
          SELECT 1 from postusers
          WHERE postusers.post_id = posts.id
          AND postusers.user_id = #{nqm.next}
          AND postusers.hidden_at IS NOT NULL
        )
      SQL
      bindings << env.session.userId
    elsif env.session.userId?
      # logged in default: listed and not hidden
      where << <<-SQL
        NOT EXISTS (
          SELECT 1 from postusers
          WHERE postusers.post_id = posts.id
          AND postusers.user_id = #{nqm.next}
          AND postusers.hidden_at IS NULL
        )
      SQL
      bindings << env.session.userId
    else
      # guest default: listed
    end

    if (tags = env.params.query["tag"]?.try(&.split(","))) && tags.size > 0
      where << <<-SQL
      EXISTS (
        SELECT 1 FROM post_tag
        JOIN tags ON tags.id = post_tag.tag_id
        WHERE post_tag.post_id = posts.id
        AND tags.active IS TRUE
        AND tags.value IN (#{tags.map { nqm.next }.join ", "})
      )
      SQL
      bindings.concat tags
    end

    domain : String? = env.params.query["domain"]?.presence
    url : String? = env.params.query["url"]?.presence
    if (url || domain)
      clause = "EXISTS (SELECT 1 FROM links WHERE "
      if domain
        clause += <<-SQL
          EXISTS (
            SELECT 1 FROM domains
            WHERE domain = #{nqm.next}
            AND links.domain_id = domains.id
          )
        SQL
        bindings << domain
      end
      if domain && url
        clause += " AND "
      end
      if url
        clause += " links.url = #{nqm.next} "
        bindings << url
      end
      clause += "AND links.id = posts.link_id)"
      where << clause
    end

    if where.size > 0
      query += "WHERE " + where.join(" AND ")
    end

    query += "ORDER BY id DESC"

    Page(self).new env do |page|
      pagination_offset_limit
      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { page.collection << self.new(rs) }
      end
    end
  end

  def self.fetch_reply_thread(env) : Kpbb::Post::Thread
    fetch_thread env
  end

  def self.fetch_thread(env) : Kpbb::Post::Thread
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM posts "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    if thread_id = (env.params.url["post_id"]? || env.params.query["post_id"]?).try(&.to_i64_from_slug_prefixed_b62?)
      where << "posts.parent_id = #{nqm.next}"
      bindings << thread_id
    end

    if parent_id = (env.params.url["parent_id"]? || env.params.query["parent_id"]?).try(&.to_i64_from_slug_prefixed_b62?)
      where << "posts.parent_id = #{nqm.next}"
      bindings << parent_id
    end

    if env.session.userId?
      where << "(posts.creator_id = #{nqm.next} OR posts.draft IS FALSE)"
      bindings << env.session.userId
    else
      where << "posts.draft IS FALSE"
    end

    if where.size > 0
      query += "WHERE " + where.join(" AND ")
    end

    query += " LIMIT 2000"
    list = Array(self).new
    Kpbb.db.query(query, args: bindings) do |rs|
      rs.each { list << self.new(rs) }
    end

    Thread.new(list)
  end
end
