module Iom::Cli::DB::Migrations
  class Migration_2021_07_16_012428_create_feed_inbound_payloads_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        DROP INDEX IF EXISTS feed_inbound_payloads_channel_id_index;
        DROP INDEX IF EXISTS feed_inbound_payloads_endpoint_id_guid_index;
        DROP INDEX IF EXISTS feed_inbound_payloads_post_id_index;
        CREATE TABLE IF NOT EXISTS feed_inbound_payloads (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          channel_id BIGINT NOT NULL,
          endpoint_id BIGINT NOT NULL,
          guid TEXT NOT NULL,
          path SMALLINT,
          data JSONB,
          result JSONB,
          post_id TEXT GENERATED ALWAYS AS (data ->> 'post_id') STORED,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        INSERT INTO feed_inbound_payloads (id, channel_id, endpoint_id, guid, path, data, result, created_at, updated_at)
        SELECT id, channel_id, endpoint_id, guid, path, data, result, created_at, updated_at
        FROM feed_inbound.payloads;
        -- CREATE INDEX IF NOT EXISTS feed_inbound_payloads_endpoint_id_index ON feed_inbound.payloads (endpoint_id);
        CREATE INDEX IF NOT EXISTS feed_inbound_payloads_channel_id_index ON feed_inbound_payloads (channel_id);
        CREATE UNIQUE INDEX IF NOT EXISTS feed_inbound_payloads_endpoint_id_guid_index ON feed_inbound_payloads (endpoint_id, guid);
        CREATE INDEX IF NOT EXISTS feed_inbound_payloads_post_id_index ON feed_inbound_payloads (post_id) WHERE post_id IS NOT NULL;
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.create_feed_inbound_payloads_table;
      SQL
    end
  end
end