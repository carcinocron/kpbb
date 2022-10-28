module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_230448_create_feed_inbound_endpoints_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE SCHEMA IF NOT EXISTS feed_inbound;
        CREATE TABLE IF NOT EXISTS feed_inbound.endpoints (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          creator_id BIGINT NOT NULL,
          channel_id BIGINT NOT NULL,
          url TEXT,
          bio TEXT,
          data JSONB,
          active BOOLEAN DEFAULT FALSE,
          mask SMALLINT DEFAULT 0,
          frequency SMALLINT DEFAULT 0, -- number of items in last 90 days
          lastpolled_at TIMESTAMPTZ,
          nextpoll_at TIMESTAMPTZ,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS feed_inbound_endpoints_active_index ON feed_inbound.endpoints (active);
        CREATE INDEX IF NOT EXISTS feed_inbound_endpoints_channel_id_index ON feed_inbound.endpoints (channel_id);
        CREATE INDEX IF NOT EXISTS feed_inbound_endpoints_creator_id_index ON feed_inbound.endpoints (creator_id);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.create_feed_inbound_endpoints_table;
      SQL
    end
  end
end
