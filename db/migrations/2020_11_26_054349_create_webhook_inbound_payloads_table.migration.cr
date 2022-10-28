module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_054349_create_webhook_inbound_payloads_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE IF NOT EXISTS webhook_inbound.payloads (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          channel_id BIGINT NOT NULL,
          endpoint_id BIGINT NOT NULL,
          cc_i16 SMALLINT,
          ip INET,
          path SMALLINT,
          data JSONB DEFAULT NULL,
          result JSONB DEFAULT NULL,
          post_id TEXT GENERATED ALWAYS AS (data ->> 'post_id') STORED, -- todo TEXT -> BIGINT
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS webhook_inbound_payloads_endpoint_id_index ON webhook_inbound.payloads (endpoint_id);
        CREATE INDEX IF NOT EXISTS webhook_inbound_payloads_channel_id_index ON webhook_inbound.payloads (channel_id);
        CREATE INDEX IF NOT EXISTS webhook_inbound_payloads_post_id_index ON webhook_inbound.payloads (post_id) WHERE post_id IS NOT NULL;
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS webhook_inbound.payloads;
      SQL
    end
  end
end
