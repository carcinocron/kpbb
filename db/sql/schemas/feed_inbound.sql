CREATE SCHEMA IF NOT EXISTS feed_inbound;
CREATE TABLE IF NOT EXISTS feed_inbound.endpoints (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  creator_id BIGINT NOT NULL,
  channel_id BIGINT NOT NULL,
  url TEXT NOT NULL,
  bio TEXT,
  data JSONB,
  active BOOLEAN DEFAULT FALSE,
  mask SMALLINT DEFAULT 0,
  frequency SMALLINT DEFAULT 0, -- number of items in last 90 days
  lastpolled_at TIMESTAMPTZ DEFAULT NULL,
  nextpoll_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS feed_inbound_endpoints_active_index ON feed_inbound.endpoints (active);
CREATE INDEX IF NOT EXISTS feed_inbound_endpoints_channel_id_index ON feed_inbound.endpoints (channel_id);
CREATE INDEX IF NOT EXISTS feed_inbound_endpoints_creator_id_index ON feed_inbound.endpoints (creator_id);

CREATE TABLE IF NOT EXISTS feed_inbound.payloads (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  channel_id BIGINT NOT NULL,
  endpoint_id BIGINT NOT NULL,
  guid TEXT NOT NULL,
  path SMALLINT,
  data JSONB DEFAULT NULL,
  result JSONB DEFAULT NULL,
  post_id TEXT GENERATED ALWAYS AS (data ->> 'post_id') STORED,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- CREATE INDEX IF NOT EXISTS feed_inbound_payloads_endpoint_id_index ON feed_inbound.payloads (endpoint_id);
CREATE INDEX IF NOT EXISTS feed_inbound_payloads_channel_id_index ON feed_inbound.payloads (channel_id);
CREATE UNIQUE INDEX IF NOT EXISTS feed_inbound_payloads_endpoint_id_guid_index ON feed_inbound.payloads (endpoint_id, guid);
CREATE INDEX IF NOT EXISTS feed_inbound_payloads_post_id_index ON feed_inbound.payloads (post_id) WHERE post_id IS NOT NULL;
