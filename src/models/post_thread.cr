private alias UserIdAndHandle = Kpbb::View::UserFromSession | Kpbb::PublicUser

struct Kpbb::Post::Thread
  property list : Array(Kpbb::Post)
  property hash : Hash(Int64, Array(Kpbb::Post))
  property post_id : Int64?
  property user : UserIdAndHandle | Nil

  def initialize(page : Page(Kpbb::Post), @user : UserIdAndHandle? = nil)
    @post_id = nil
    @hash = Hash(Int64, Array(Kpbb::Post)).new
    @list = page.collection
  end

  def initialize(@list, @post_id : Int64? = nil, @user : UserIdAndHandle? = nil)
    parent_id : Int64 = 0_i64
    @hash = Hash(Int64, Array(Kpbb::Post)).new
    @list.each do |p|
      parent_id = p.parent_id || 0_i64
      if @hash.has_key? parent_id
        @hash[parent_id] << p
      else
        @hash[parent_id] = [p]
      end
    end
  end

  def initialize(
    @list,
    @hash,
    @post_id : Int64? = nil,
    @user : UserIdAndHandle | Nil = nil
  )
  end

  def initialize
    @list = Array(Kpbb::Post).new
    @hash = Hash(Int64, Array(Kpbb::Post)).new
    @post_id = nil
    @user = nil
  end

  def to_ids_only_hash_array : Hash(Int64, Array(Int64))
    map = Hash(Int64, Array(Int64)).new
    @hash.each do |key, value|
      map[key] = value.map(&.id)
    end
    map
  end

  def context? : Post?
    return nil unless @post_id
    @list.find { |p| p.id == @post_id }
  end

  def context : Post
    context?.not_nil!
  end

  def children?(context : Post) : Array(Post)?
    if list = @hash[context.id]?
      list
    end
  end

  def children?(context_id : Int64) : Array(Post)?
    if list = @hash[context_id]?
      list
    end
  end

  def children? : Array(Post)?
    if (context = context?)
      children?(context)
    end
  end

  def children(val) : Array(Post)
    children?(val) || Array(Post)
  end
  def children : Array(Post)
    children? || Array(Post)
  end

  def has_children? : Bool
    !(children = children?).nil? && children.size > 0
  end

  def has_parents? : Bool
    if context = context?
      if parent_id = context.parent_id
        if size = @hash[parent_id]?.try(&.size)
          return size > 0
        end
      end
    end
    false
  end

  def parents : Array(Post)
    list = Array(Post).new
    post : Post? = self.context
    loop do
      return list unless post
      return list unless parent_id = post.parent_id
      post = @list.find { |p| p.id == parent_id }
      if post
        list.unshift post
      end
    end
  end

  def self.fetch(
    post_id : Int64,
    user : UserIdAndHandle | Nil = nil,
    children : Bool = true
  ) : Kpbb::Post::Thread
    nqm = NextQuestionMark.new
    query = IO::Memory.new
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    # I wanted to limit it to X=3 children, Y=2 parents,
    # but the full recursion seemed to just work as is
    # so when posts get huge we'll have to make a design-or-cache
    # choice, maybe `WITH RECURSIVE p` can become `WITH RECURSIVE p(n) `
    # it's not SQL injection because post_id is known int at compile time
    # `WHERE p.posted IS FALSE` if a post is "posted" (a reply as a new thread)
    # then we should cut off it's children for this thread/context
    if children
      query << <<-SQL
      SELECT #{Kpbb::Post.select}
      FROM ((
        -- select parents
        WITH RECURSIVE p AS (
          SELECT * FROM posts WHERE posts.id = #{post_id}
          UNION ALL
          SELECT posts.* FROM posts
          JOIN p ON posts.id = p.parent_id
          WHERE (p.posted IS FALSE OR p.id = #{post_id})
        )
        SELECT * FROM p
      ) UNION (
        -- select children
        WITH RECURSIVE p AS (
          SELECT * FROM posts WHERE posts.parent_id = #{post_id}
          UNION ALL
          SELECT posts.* FROM posts
          JOIN p ON posts.parent_id = p.id
          WHERE p.posted IS FALSE
        )
        SELECT * FROM p
      )) as posts
      SQL
    else # children: false
      query << <<-SQL
      SELECT #{Kpbb::Post.select}
      FROM (
        -- select parents
        WITH RECURSIVE p AS (
          SELECT * FROM posts WHERE posts.id = #{post_id}
          UNION ALL
          SELECT posts.* FROM posts JOIN p ON posts.id = p.parent_id
        )
        SELECT * FROM p
      ) as posts
      SQL
    end

    if where.size > 0
      query << " WHERE " + where.join(" AND ")
    end

    query << " ORDER BY posts.id ASC"
    query << " LIMIT 2000"
    list = Array(Kpbb::Post).new
    # pp ({:query => query, :bindings => bindings})
    Kpbb.db.query(query.to_s, args: bindings) do |rs|
      rs.each { list << Kpbb::Post.new(rs) }
    end

    Thread.new(list, post_id: post_id, user: user)
  end

  @channels : Array(Kpbb::Channel)?

  def channels : Array(Kpbb::Channel)
    @channels ||= Kpbb::Channel.find(@list.map(&.channel_id))
  end

  @publicusers : Array(Kpbb::PublicUser)?

  def publicusers : Array(Kpbb::PublicUser)
    @publicusers ||= Kpbb::PublicUser.find(@list.compact_map(&.creator_id))
  end

  @postusers : Array(Kpbb::PostUser)?

  def postusers : Array(Kpbb::PostUser)
    @postusers ||= if (user = @user)
                     Kpbb::PostUser.find(
                       post_id_list: @list.map(&.channel_id),
                       user_id: user.id)
                   else
                     Array(Kpbb::PostUser).new
                   end
  end

  @channelmemberships : Array(Kpbb::ChannelMembership)?

  def channelmemberships : Array(Kpbb::ChannelMembership)
    @channelmemberships ||= if (user = @user)
                              Kpbb::ChannelMembership.find(
                                channel_id_list: @list.map(&.channel_id),
                                user_id: user.id)
                            else
                              Array(Kpbb::ChannelMembership).new
                            end
  end

  @links : Array(Kpbb::Link)?

  def links : Array(Kpbb::Link)
    @links ||= Kpbb::Link.find(@list.compact_map(&.link_id))
  end

  def link(post : Kpbb::Post) : Kpbb::Link?
    (link_id = post.link_id) ? links.find { |l| l.id == link_id } : nil
  end
end
