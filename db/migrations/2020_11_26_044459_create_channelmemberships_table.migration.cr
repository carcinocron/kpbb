module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044459_create_channelmemberships_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.channelmemberships (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          channel_id BIGINT NOT NULL,
          user_id BIGINT NOT NULL,
          rank SMALLINT DEFAULT 0,
          banned BOOLEAN DEFAULT FALSE,
          hidden_at TIMESTAMPTZ,
          follow BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMP NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMP NOT NULL DEFAULT NOW()
        );
        CREATE UNIQUE INDEX IF NOT EXISTS channelmemberships_channel_id_user_id_unique ON channelmemberships (channel_id, user_id);
        CREATE INDEX IF NOT EXISTS channelmemberships_channel_id_index ON channelmemberships (channel_id);
        CREATE INDEX IF NOT EXISTS channelmemberships_user_id_index ON channelmemberships (user_id);
        CREATE INDEX IF NOT EXISTS channelmemberships_user_id_follow_index ON channelmemberships (user_id, follow, channel_id);
        CREATE INDEX IF NOT EXISTS channelmemberships_user_id_hidden_at_index ON channelmemberships (user_id, hidden_at, channel_id);
        CREATE INDEX IF NOT EXISTS channelmemberships_user_id_rank_index ON channelmemberships (user_id, rank, channel_id);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.channelmemberships;
      SQL
    end
  end
end
