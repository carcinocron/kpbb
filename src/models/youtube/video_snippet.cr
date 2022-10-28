struct Kpbb::Youtube::VideoSnippet
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_string_key(video_id)
  # Kpbb::Util::Model.find_by_http_env("youtube_video_id")
  @@table = "youtube_video_snippets"

  def self.select_columns : Array(String)
    ["video_id", "channel_id",
     "youtube_video_snippets.data ->> 'channelTitle' as channel_title",
     "youtube_video_snippets.data ->> 'title' as title",
     "youtube_video_snippets.data ->> 'description' as bio",
     "published_at", "updated_at"]
  end

  property video_id : String?
  property channel_id : String?
  property channel_title : String?
  property title : String?
  property bio : String?
  property published_at : Time?
  property updated_at : Time?

  def initialize(
    @video_id : String,
    @channel_id : String,
    @channel_title : String,
    @title : String,
    @bio : String?,
    # @data : String,
    @published_at : Time? = nil,
    @updated_at : Time = Time.utc
  )
  end

  def initialize(rs : DB::ResultSet)
    @video_id = rs.read(typeof(@video_id))
    @channel_id = rs.read(typeof(@channel_id))
    @channel_title = rs.read(typeof(@channel_title))
    @title = rs.read(typeof(@title))
    @bio = rs.read(typeof(@bio))
    # we're going to keep this as TEXT during runtime
    # to not anger the type system
    # @data = rs.read(JSON::Any?).to_json
    @published_at = rs.read(Time?)
    @updated_at = rs.read(Time?)
  end

  def self.save!(video_id : String, data : String, connection : DB::Connection? = nil)
    connection ||= Kpbb.db
    query = <<-SQL
      INSERT INTO #{@@table} (video_id, channel_id, data, updated_at)
      VALUES ($1, $2::JSONB - 'localized', NOW())
      ON CONFLICT (video_id) DO UPDATE
      data = excluded.data,
      updated_at = excluded.updated_at,
      published_at = COALESCE((excluded.data -> 'published_at')::TEXT, (excluded.data -> 'publishedAt')::TEXT)::TIMESTAMPTZ AT TIME ZONE 'UTC'
    SQL
    connection.exec(query, args: [
      video_id,
      data,
    ])
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    channel_id : String = (env.params.url["channel_id"]? || env.params.query["channel_id"]?)
    if channel_id
      where << "channel_id = #{nqm.next}"
      bindings << channel_id
    end

    # pagination_before_after "youtube_video_snippets"

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
