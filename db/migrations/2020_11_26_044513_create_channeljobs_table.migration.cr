module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044513_create_channeljobs_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.channeljobs (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          user_id BIGINT,
          channel_id BIGINT,
          post_id BIGINT,
          comment_id BIGINT,
          action SMALLINT,
          data JSONB,
          run_at TIMESTAMPTZ,
          queued BOOLEAN,
          created_at TIMESTAMPTZ
        );
        CREATE INDEX IF NOT EXISTS channeljobs_user_id_index ON channeljobs (user_id);
        CREATE INDEX IF NOT EXISTS channeljobs_channel_id_index ON channeljobs (channel_id);
        CREATE INDEX IF NOT EXISTS channeljobs_post_id_index ON channeljobs (post_id);
        CREATE INDEX IF NOT EXISTS channeljobs_comment_id_index ON channeljobs (comment_id);
        CREATE INDEX IF NOT EXISTS channeljobs_channel_id_action_index ON channeljobs (channel_id, action);
        CREATE INDEX IF NOT EXISTS channeljobs_channel_id_user_id_index ON channeljobs (channel_id, user_id);
        CREATE INDEX IF NOT EXISTS channeljobs_action_index ON channellogs (action);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.channeljobs;
      SQL
    end
  end
end
