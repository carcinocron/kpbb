module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044503_create_postusers_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.postusers (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          post_id BIGINT NOT NULL,
          user_id BIGINT NOT NULL,
          vote SMALLINT,
          updated_at TIMESTAMPTZ,
          saved_at TIMESTAMPTZ,
          hidden_at TIMESTAMPTZ,
          flagged_at TIMESTAMPTZ,
          voted_at TIMESTAMPTZ,
          read_at TIMESTAMPTZ -- when you last viewed the thread
        );
        CREATE UNIQUE INDEX IF NOT EXISTS postusers_post_id_user_id_unique ON postusers (post_id, user_id);
        CREATE INDEX IF NOT EXISTS postusers_post_id_index ON postusers (post_id);
        CREATE INDEX IF NOT EXISTS postusers_user_id_index ON postusers (user_id);
        CREATE INDEX IF NOT EXISTS postusers_user_id_saved_at_index ON postusers (user_id, saved_at);
        CREATE INDEX IF NOT EXISTS postusers_user_id_hidden_at_index ON postusers (user_id, hidden_at);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.postusers;
      SQL
    end
  end
end
