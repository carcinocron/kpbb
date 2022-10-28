CREATE SCHEMA IF NOT EXISTS flag;
CREATE TABLE IF NOT EXISTS flag.flags (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  avatar TEXT,
  bio TEXT,
  active BOOLEAN DEFAULT FALSE,
  sortw SMALLINT DEFAULT 0, -- sort weight
  lastactive_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS flag_flags_active_index ON flag.flags (active);
CREATE INDEX IF NOT EXISTS flag_flags_active_sortw_index ON flag.flags (active, sortw);
-- ALTER TABLE flag.flags ADD CONSTRAINT flag_flags_name_length CHECK (char_length(name) > 2);
  -- first character must be letter, last character must not be dash or underscore
-- ALTER TABLE flag.flags ADD CONSTRAINT flag_flags_name_regex CHECK (name ~ '^[a-zA-Z][a-zA-Z0-9_\-]+[a-zA-Z0-9]$');
-- CREATE UNIQUE INDEX flag_flags_name_unique_lowercase ON flag.flags (lower(name));

CREATE TABLE IF NOT EXISTS flag.items (
  flag_id BIGINT,
  reporter_id BIGINT,
  user_id BIGINT,
  channel_id BIGINT,
  post_id BIGINT,
  comment_id BIGINT,
  msg TEXT,
  active BOOL,
  created_at TIME,
);

CREATE INDEX IF NOT EXISTS flags_items_channel_id_flag_id_index ON flag.items (channel_id, flag_id);
CREATE INDEX IF NOT EXISTS flags_items_flag_id_index ON flag.items (flag_id);
CREATE INDEX IF NOT EXISTS flags_items_channel_id_index ON flag.items (channel_id, flag_id) WHERE post_id IS NULL;
CREATE INDEX IF NOT EXISTS flags_items_channel_id_index ON flag.items (channel_id, post_id, flag_id) WHERE post_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS flags_items_channel_id_index ON flag.items (channel_id, comment_id, flag_id) WHERE comment_id IS NOT NULL;

