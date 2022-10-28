module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_054348_create_webhook_inbound_endpoints_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE SCHEMA IF NOT EXISTS webhook_inbound;
        CREATE TABLE IF NOT EXISTS webhook_inbound.endpoints (
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
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS webhook_inbound_endpoints_active_index ON webhook_inbound.endpoints (active);
        CREATE INDEX IF NOT EXISTS webhook_inbound_endpoints_channel_id_index ON webhook_inbound.endpoints (channel_id);
        CREATE INDEX IF NOT EXISTS webhook_inbound_endpoints_creator_id_index ON webhook_inbound.endpoints (creator_id);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS webhook_inbound.endpoints;
      SQL
    end
  end
end
