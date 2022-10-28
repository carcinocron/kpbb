module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044500_create_posts_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.posts (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          channel_id BIGINT NOT NULL,
          parent_id BIGINT,
          creator_id BIGINT,
          title TEXT,
          tags TEXT,
          url TEXT,
          link_id BIGINT,
          body_md TEXT,
          body_html TEXT,
          score INTEGER,
          dreplies SMALLINT,
          treplies SMALLINT,
          mask SMALLINT DEFAULT 0,
          cc_i16 SMALLINT,
          ip INET,
          active BOOLEAN NOT NULL DEFAULT FALSE,
          locked BOOLEAN NOT NULL DEFAULT FALSE,
          dead BOOLEAN NOT NULL DEFAULT FALSE,
          draft BOOLEAN NOT NULL DEFAULT TRUE,
          sageru BOOLEAN,
          published_at TIMESTAMPTZ,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS posts_active_index ON posts (active);
        CREATE INDEX IF NOT EXISTS posts_link_id_index ON posts (link_id);
        CREATE INDEX IF NOT EXISTS posts_channel_id_index ON posts (channel_id);
        CREATE INDEX IF NOT EXISTS posts_creator_id_index ON posts (creator_id);
        CREATE INDEX IF NOT EXISTS posts_mask_creator_id_index ON posts (mask, creator_id);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.posts;
      SQL
    end
  end
end
