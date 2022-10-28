module Iom::Cli::DB::Migrations
  class Migration_2021_07_15_202602_create_webhook_inbound_endpoints_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        DROP INDEX IF EXISTS webhook_inbound_endpoints_active_index;
        DROP INDEX IF EXISTS webhook_inbound_endpoints_channel_id_index;
        DROP INDEX IF EXISTS webhook_inbound_endpoints_creator_id_index;
        CREATE TABLE IF NOT EXISTS webhook_inbound_endpoints (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          creator_id BIGINT NOT NULL,
          channel_id BIGINT NOT NULL,
          uuid UUID NOT NULL UNIQUE,
          secret TEXT NOT NULL,
          bio TEXT,
          data JSONB,
          active BOOLEAN DEFAULT FALSE,
          mask SMALLINT DEFAULT 0,
          lastactive_at TIMESTAMPTZ DEFAULT NULL,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW(),
          lastposted_at TIMESTAMPTZ,
          nextpost_at TIMESTAMPTZ,
          default_body JSONB
        );
        INSERT INTO webhook_inbound_endpoints (id, creator_id, channel_id, uuid, secret, bio, data, active, mask, lastactive_at, created_at, updated_at, lastposted_at, nextpost_at, default_body)
        SELECT id, creator_id, channel_id, uuid, secret, bio, data, active, mask, lastactive_at, created_at, updated_at, lastposted_at, nextpost_at, default_body
        FROM webhook_inbound.endpoints;
        DROP TABLE webhook_inbound.endpoints;
        CREATE INDEX IF NOT EXISTS webhook_inbound_endpoints_active_index ON webhook_inbound_endpoints (active);
        CREATE INDEX IF NOT EXISTS webhook_inbound_endpoints_channel_id_index ON webhook_inbound_endpoints (channel_id);
        CREATE INDEX IF NOT EXISTS webhook_inbound_endpoints_creator_id_index ON webhook_inbound_endpoints (creator_id);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.webhook_inbound_endpoints;
      SQL
    end
  end
end