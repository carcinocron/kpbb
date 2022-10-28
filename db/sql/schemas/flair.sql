CREATE SCHEMA IF NOT EXISTS flair;
CREATE TABLE IF NOT EXISTS flair.bots (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  handle TEXT NOT NULL,
  avatar TEXT,
  bio TEXT,
  active BOOLEAN DEFAULT FALSE,
  lastactive_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS flair_bots_active_index ON flair.bots (active);
ALTER TABLE flair.bots ADD CONSTRAINT flair_bots_handle_length CHECK (char_length(handle) > 2);
  -- first character must be letter, last character must not be dash or underscore
ALTER TABLE flair.bots ADD CONSTRAINT flair_bots_handle_regex CHECK (handle ~ '^[a-zA-Z][a-zA-Z0-9_\-]+[a-zA-Z0-9]$');
CREATE UNIQUE INDEX flair_bots_handle_unique_lowercase ON flair.bots (lower(handle));

CREATE TABLE IF NOT EXISTS flair.item (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  bot_id BIGINT,
  key TEXT NOT NULL,
  line TEXT NOT NULL,
  body_md TEXT NOT NULL,
  active BOOLEAN DEFAULT FALSE,
  lastactive_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS flair_item_bot_id_key_index ON flair.item (bot_id, key);
CREATE INDEX IF NOT EXISTS flair_item_active_index ON flair.item (active);

CREATE TABLE IF NOT EXISTS flair.comment (
  flair_id BIGINT,
  comment_id BIGINT
);

CREATE INDEX IF NOT EXISTS flair_comment_comment_id_flair_id_index ON flair.comment (comment_id, flair_id);
CREATE INDEX IF NOT EXISTS flair_comment_flair_id_comment_id_index ON flair.comment (flair_id, comment_id);

CREATE TABLE IF NOT EXISTS flair.post (
  flair_id BIGINT,
  post_id BIGINT
);

CREATE INDEX IF NOT EXISTS flair_post_post_id_flair_id_index ON flair.post (post_id, flair_id);
CREATE INDEX IF NOT EXISTS flair_post_flair_id_post_id_index ON flair.post (flair_id, post_id);
