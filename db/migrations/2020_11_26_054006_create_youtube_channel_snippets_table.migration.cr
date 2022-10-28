module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_054006_create_youtube_channel_snippets_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE IF NOT EXISTS youtube.channel_snippets (
          channel_id TEXT UNIQUE,
          data JSONB,
          updated_at TIMESTAMPTZ
        );
        -- CREATE INDEX IF NOT EXISTS youtube_channel_snippets_channel_id_index ON youtube.channel_snippets (channel_id); --  created implicitly
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS youtube.channel_snippets;
      SQL
    end
  end
end
