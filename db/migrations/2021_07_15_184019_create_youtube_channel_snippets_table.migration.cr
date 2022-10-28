module Iom::Cli::DB::Migrations
  class Migration_2021_07_15_184019_create_youtube_channel_snippets_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE IF NOT EXISTS public.youtube_channel_snippets (
          channel_id TEXT UNIQUE,
          data JSONB,
          updated_at TIMESTAMPTZ
        );
        INSERT INTO youtube_channel_snippets (channel_id, data, updated_at)
        SELECT channel_id, data, updated_at FROM youtube.channel_snippets;
        DROP TABLE youtube.channel_snippets;
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.youtube_channel_snippets;
      SQL
    end
  end
end