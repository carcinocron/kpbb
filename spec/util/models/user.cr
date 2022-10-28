struct TestUser
  property id : Int64
  property pw_id : Int64
  property handle : String
  property dname : String
  @[Kpbb::Orm::Column]
  str_getter avatar
  @[Kpbb::Orm::Column]
  str_getter banner
  property bio : String?
  property pronouns : String
  property rank : Int16
  property created_at : Time

  def initialize(
    @handle : String = "handle1",
    dname : String? = nil,
    @avatar : String? = nil,
    @banner : String? = nil,
    @bio : String? = nil,
    @pronouns : String = "",
    @rank : Int16 = 0_i16,
    @trust : Int16 = 0_i16
  )
    @dname = dname || @handle
    @id, @created_at = Kpbb.db.query_one <<-SQL,
      INSERT INTO users (handle, dname, avatar, banner, bio, pronouns, rank, trust, theme_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 0) returning id, created_at
    SQL
      args: [
        @handle,
        @dname,
        @avatar,
        @banner,
        @bio,
        @pronouns,
        @rank,
        @trust,
      ], as: {Int64, Time}

    Kpbb.db.exec("CALL update_user_password($1, $2, $3)", args: [
      @id,
      hashed_password,
      -1, # @todo password strength
    ])

    @pw_id = 0

    # @id, @pw_id, @created_at = Kpbb.db.query_one("CALL test_insert_user($1, $2, $3, $4, $5, $6)", args: [
    #   hashed_password,
    #   nil, # @todo password strength
    #   @handle,
    #   @avatar,
    #   @bio,
    #   @rank,
    # ], as: {Int64, Int64, Time})
  end

  def initialize(@id : Int64)
    query = <<-SQL
      SELECT id, handle, dname, pw_id, avatar, banner,
        bio, pronouns, rank, trust, created_at
      FROM users WHERE id = $1
    SQL

    id, @handle, @dname, @pw_id, @avatar, @banner, @bio, @pronouns, @rank, @trust, @created_at = Kpbb.db.query_one query, args: [
      @id,
    ], as: {Int64, String, String, Int64, String?, String?,
            String, String, Int16, Int16, Time}
  end

  property cookie : String?

  def login!
    body = HTTP::Params.build do |form|
      form.add "handle", @handle
      form.add "password", plaintext_password
    end
    req = HTTP::Request.new("POST", "/login", default_browser_post_headers.merge!(accepts_json), body.to_s)
    res = process_request req
    @cookie = res.headers["Set-Cookie"]
    # puts res.headers["Set-Cookie"]
  end

  def request(method, path, headers, body)
    self.login! if @cookie.nil?
    headers["cookie"] = @cookie.not_nil!
    # headers.merge! @cookie.not_nil!
    HTTP::Request.new(method, path, headers, body)
  end

  def view_context(path : String, method : String = "GET", headers = nil, body = nil) : Kpbb::View::Context
    Kpbb::View::Context.new(HTTP::Request.new(method, path, headers, body), user: self)
  end

  def to_public_user : Kpbb::PublicUser
    Kpbb::PublicUser.new(
      id: @id,
      handle: @handle,
      dname: @dname,
      bio: @bio,
      avatar: @avatar,
      banner: @banner,
      pronouns: @pronouns)
  end
end
