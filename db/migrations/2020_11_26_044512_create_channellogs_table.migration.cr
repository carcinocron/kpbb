module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044512_create_channellogs_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.channellogs (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          user_id BIGINT,
          channel_id BIGINT,
          post_id BIGINT,
          comment_id BIGINT,
          action SMALLINT,
          data JSONB,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS channellogs_user_id_index ON channellogs (user_id);
        CREATE INDEX IF NOT EXISTS channellogs_channel_id_index ON channellogs (channel_id);
        CREATE INDEX IF NOT EXISTS channellogs_post_id_index ON channellogs (post_id);
        CREATE INDEX IF NOT EXISTS channellogs_comment_id_index ON channellogs (comment_id);
        CREATE INDEX IF NOT EXISTS channellogs_channel_id_action_index ON channellogs (channel_id, action);
        CREATE INDEX IF NOT EXISTS channellogs_channel_id_user_id_index ON channellogs (channel_id, user_id);
        CREATE INDEX IF NOT EXISTS channellogs_action_index ON channellogs (action);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.channellogs;
      SQL
    end
  end
end
