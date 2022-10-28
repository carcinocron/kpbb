require "get-youtube-id"

module Kpbb::Cron::RecentYoutubeVideos
  def self.run(minute : Time) : Nil
    unless ENV["YOUTUBE_API_KEY"]?
      Log.info { "undefined YOUTUBE_API_KEY" }
    end
    bindings = Array(String | Time).new
    query = <<-SQL
    SELECT (meta ->> 'youtube_id') as youtube_id
    FROM links
    WHERE (meta ->> 'youtube_id') IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM youtube_video_snippets
      WHERE youtube_video_snippets.video_id = (links.meta ->> 'youtube_id')
      AND updated_at > $1
    )
    ORDER BY lastseen_at DESC
    LIMIT 20
    SQL

    # WHERE lastseen_at > ?
    bindings << minute - 1.day
    # bindings << minute - 1.hour

    ytvideo_id_list = Array(String).new
    Kpbb.db.query(query, args: bindings) do |rs|
      rs.each { ytvideo_id_list << rs.read(String) }
    end
    # pp ytvideo_id_list

    Kpbb::Youtube.sync_video_snippets(ytvideo_id_list)
  end
end

module Kpbb::Cron::RecentYoutubeChannels
  def self.run(minute : Time) : Nil
    unless ENV["YOUTUBE_API_KEY"]?
      Log.info { "undefined YOUTUBE_API_KEY" }
    end
    bindings = Array(String | Time).new
    query = <<-SQL
    SELECT channel_id FROM youtube_video_snippets
    WHERE updated_at > $1
    AND NOT EXISTS (
      SELECT 1 FROM youtube_channel_snippets
      WHERE youtube_channel_snippets.channel_id = youtube_video_snippets.channel_id
      AND updated_at > $2
    )
    ORDER BY youtube_video_snippets.updated_at DESC
    LIMIT 20
    SQL

    # WHERE lastseen_at > ?
    bindings << minute - 1.hour
    bindings << minute - 1.day

    ytchannel_id_list = Array(String).new
    Kpbb.db.query(query, args: bindings) do |rs|
      rs.each { ytchannel_id_list << rs.read(String) }
    end
    # pp ytchannel_id_list

    Kpbb::Youtube.sync_channel_snippets(ytchannel_id_list)
  end
end
