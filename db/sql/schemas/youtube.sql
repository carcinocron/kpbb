CREATE SCHEMA IF NOT EXISTS youtube;
CREATE TABLE IF NOT EXISTS youtube.video_snippets (
  video_id TEXT UNIQUE,
  data JSONB,
  channel_id TEXT GENERATED ALWAYS AS (data ->> 'channelId') STORED,
  published_at TIMESTAMPTZ, -- GENERATED ALWAYS AS (((data -> 'publishedAt')::TEXT)::TIMESTAMP AT TIME ZONE 'UTC') STORED,
  updated_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS youtube_video_snippets_channel_id_index ON youtube.video_snippets (channel_id);
CREATE INDEX IF NOT EXISTS youtube_video_snippets_channel_id_video_id_index ON youtube.video_snippets (channel_id, video_id);
CREATE INDEX IF NOT EXISTS youtube_video_snippets_channel_id_published_at_index ON youtube.video_snippets (channel_id, published_at);

CREATE TABLE IF NOT EXISTS youtube.channel_snippets (
  channel_id TEXT UNIQUE,
  data JSONB,
  updated_at TIMESTAMPTZ
);
-- CREATE INDEX IF NOT EXISTS youtube_channel_snippets_channel_id_index ON youtube.channel_snippets (channel_id); --  created implicitly
