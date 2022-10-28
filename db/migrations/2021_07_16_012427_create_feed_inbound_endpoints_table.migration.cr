module Iom::Cli::DB::Migrations
  class Migration_2021_07_16_012427_create_feed_inbound_endpoints_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        DROP INDEX IF EXISTS feed_inbound_endpoints_active_index;
        DROP INDEX IF EXISTS feed_inbound_endpoints_channel_id_index;
        DROP INDEX IF EXISTS feed_inbound_endpoints_creator_id_index;
        CREATE TABLE public.feed_inbound_endpoints (
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
          updated_at TIMESTAMPTZ DEFAULT NOW(),
          lastposted_at TIMESTAMPTZ,
          nextpost_at TIMESTAMPTZ,
          default_body JSONB
        );
        INSERT INTO public.feed_inbound_endpoints (id, creator_id, channel_id, url, bio, data, active, mask, frequency, lastpolled_at, nextpoll_at, created_at, updated_at)
        SELECT id, creator_id, channel_id, url, bio, data, active, mask, frequency, lastpolled_at, nextpoll_at, created_at, updated_at
        FROM feed_inbound.endpoints;
        DROP TABLE feed_inbound.endpoints;
        CREATE INDEX IF NOT EXISTS feed_inbound_endpoints_active_index ON feed_inbound_endpoints (active);
        CREATE INDEX IF NOT EXISTS feed_inbound_endpoints_channel_id_index ON feed_inbound_endpoints (channel_id);
        CREATE INDEX IF NOT EXISTS feed_inbound_endpoints_creator_id_index ON feed_inbound_endpoints (creator_id);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.feed_inbound_endpoints;
      SQL
    end
  end
end