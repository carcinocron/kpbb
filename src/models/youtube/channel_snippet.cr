struct Kpbb::Youtube::ChannelSnippet
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_string_key(channel_id)
  # Kpbb::Util::Model.find_by_http_env("youtube_channel_id")
  @@table = "youtube_channel_snippets"

  def self.select_columns : Array(String)
    ["channel_id",
     "youtube_channel_snippets.data ->> 'title' as title",
     "youtube_channel_snippets.data ->> 'description' as bio",
     "updated_at"]
  end

  property channel_id : String?
  property title : String?
  property bio : String?
  property updated_at : Time?

  def initialize(
    @channel_id : String,
    @title : String,
    @bio : String?,
    # @data : String,
    @updated_at : Time = Time.utc
  )
  end

  def initialize(rs : DB::ResultSet)
    @channel_id = rs.read(String)
    @title = rs.read(typeof(@title))
    @bio = rs.read(typeof(@bio))
    # we're going to keep this as TEXT during runtime
    # to not anger the type system
    # @data = rs.read(JSON::Any?).to_json
    @updated_at = rs.read(Time)
  end

  def self.save!(channel_id : String, data : String, connection : DB::Connection? = nil)
    connection ||= Kpbb.db
    connection.exec(<<-SQL,
      INSERT INTO #{@@table} (channel_id, channel_id, data, updated_at)
      VALUES ($1, $2::JSONB - 'localized', NOW())
      ON CONFLICT (channel_id) DO UPDATE
      data = excluded.data,
      updated_at = excluded.updated_at
    SQL


      args: [
        channel_id,
        data,
      ])
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    # channel_id : String = (env.params.url["channel_id"]? || env.params.query["channel_id"]?)
    # if channel_id
    #   where << "channel_id = #{nqm.next}"
    #   bindings << channel_id
    # end

    # pagination_before_after "youtube_channel_snippets"

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
