module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_054005_create_youtube_video_snippets_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE SCHEMA IF NOT EXISTS youtube;
        CREATE TABLE IF NOT EXISTS youtube.video_snippets (
          video_id TEXT UNIQUE,
          data JSONB,
          channel_id TEXT GENERATED ALWAYS AS (data ->> 'channelId') STORED,
          published_at TIMESTAMPTZ, -- GENERATED ALWAYS AS (((data -> 'publishedAt')::TEXT)::TIMESTAMP AT TIME ZONE 'UTC') STORED,
          updated_at TIMESTAMPTZ
        );
        CREATE INDEX IF NOT EXISTS youtube_video_snippets_channel_id_index ON youtube.video_snippets (channel_id);
        CREATE INDEX IF NOT EXISTS youtube_video_snippets_channel_id_video_id_index ON youtube.video_snippets (channel_id, video_id);
        CREATE INDEX IF NOT EXISTS youtube_video_snippets_channel_id_published_at_index ON youtube.video_snippets (channel_id, published_at);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS youtube.video_snippets;
      SQL
    end
  end
end
