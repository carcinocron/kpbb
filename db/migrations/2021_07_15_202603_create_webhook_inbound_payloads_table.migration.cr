module Iom::Cli::DB::Migrations
  class Migration_2021_07_15_202603_create_webhook_inbound_payloads_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        DROP INDEX IF EXISTS webhook_inbound_payloads_endpoint_id_index;
        DROP INDEX IF EXISTS webhook_inbound_payloads_channel_id_index;
        DROP INDEX IF EXISTS webhook_inbound_payloads_post_id_index;
        CREATE TABLE IF NOT EXISTS webhook_inbound_payloads (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          channel_id BIGINT NOT NULL,
          endpoint_id BIGINT NOT NULL,
          cc_i16 SMALLINT,
          ip INET,
          path SMALLINT,
          data JSONB DEFAULT NULL,
          result JSONB DEFAULT NULL,
          post_id TEXT GENERATED ALWAYS AS (data ->> 'post_id') STORED,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        INSERT INTO webhook_inbound_payloads (id, channel_id, endpoint_id, cc_i16, ip, path, data, result, created_at, updated_at)
        SELECT id, channel_id, endpoint_id, cc_i16, ip, path, data, result, created_at, updated_at FROM webhook_inbound.payloads;
        DROP TABLE webhook_inbound.payloads;
        CREATE INDEX IF NOT EXISTS webhook_inbound_payloads_endpoint_id_index ON webhook_inbound_payloads (endpoint_id);
        CREATE INDEX IF NOT EXISTS webhook_inbound_payloads_channel_id_index ON webhook_inbound_payloads (channel_id);
        CREATE INDEX IF NOT EXISTS webhook_inbound_payloads_post_id_index ON webhook_inbound_payloads (post_id) WHERE post_id IS NOT NULL;
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.create_webhook_inbound_payloads_table;
      SQL
    end
  end
end