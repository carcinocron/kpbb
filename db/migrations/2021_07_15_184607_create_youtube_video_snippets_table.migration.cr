module Iom::Cli::DB::Migrations
  class Migration_2021_07_15_184607_create_youtube_video_snippets_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        DROP INDEX IF EXISTS youtube_video_snippets_channel_id_index;
        DROP INDEX IF EXISTS youtube_video_snippets_channel_id_video_id_index;
        DROP INDEX IF EXISTS youtube_video_snippets_channel_id_published_at_index;
        CREATE TABLE IF NOT EXISTS youtube_video_snippets (
          video_id TEXT UNIQUE,
          data JSONB,
          channel_id TEXT GENERATED ALWAYS AS ((data ->> 'snippet')::JSONB ->> 'channelId') STORED,
          published_at TIMESTAMPTZ, -- GENERATED ALWAYS AS (((data -> 'publishedAt')::TEXT)::TIMESTAMP AT TIME ZONE 'UTC') STORED,
          updated_at TIMESTAMPTZ
        );
        INSERT INTO youtube_video_snippets (video_id, data, published_at, updated_at)
        SELECT video_id, data, published_at, updated_at FROM youtube.video_snippets;
        DROP TABLE IF EXISTS youtube.video_snippets;
        CREATE INDEX IF NOT EXISTS youtube_video_snippets_channel_id_index ON youtube_video_snippets (channel_id);
        CREATE INDEX IF NOT EXISTS youtube_video_snippets_channel_id_video_id_index ON youtube_video_snippets (channel_id, video_id);
        CREATE INDEX IF NOT EXISTS youtube_video_snippets_channel_id_published_at_index ON youtube_video_snippets (channel_id, published_at);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.youtube_video_snippets;
      SQL
    end
  end
end