CREATE TABLE appsettingskv (
  k TEXT NOT NULL,
  v TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS appsettingskv_k_unique ON appsettingskv (k);

CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  handle TEXT NOT NULL,
  dname TEXT NOT NULL, -- display_name
  pronouns TEXT,
  lang TEXT,
  -- email TEXT,
  pw_id BIGINT,
  mfa_id BIGINT,
  avatar TEXT,
  banner TEXT,
  bio TEXT,
  active BOOLEAN DEFAULT FALSE,
  rank SMALLINT DEFAULT 0, -- admin if > 0
  trust SMALLINT DEFAULT 0, -- if user is in good standing
  theme_id SMALLINT DEFAULT 0,
  pref JSONB,
  lastlogin_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ALTER TABLE users ADD CONSTRAINT users_email_length CHECK (email IS NULL OR char_length(email) > 5);
-- ALTER TABLE users ADD CONSTRAINT users_email_lowercase CHECK (email = lower(email));
-- CREATE UNIQUE INDEX users_email_unique_lowercase ON users (lower(email));
CREATE INDEX IF NOT EXISTS users_active_index ON users (active);
ALTER TABLE users ADD CONSTRAINT users_handle_length CHECK (char_length(handle) > 2);
  -- first character must be letter, last character must not be dash or underscore
ALTER TABLE users ADD CONSTRAINT users_handle_regex CHECK (handle ~ '^[a-zA-Z][a-zA-Z0-9_\-]+[a-zA-Z0-9]$');
CREATE UNIQUE INDEX users_handle_unique_lowercase ON users (lower(handle));

-- DROP INDEX IF EXISTS users_email_unique;
-- CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique ON users (lower(email)) WHERE email IS NOT NULL;


CREATE TABLE passwords (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  user_id BIGINT,
  strength SMALLINT DEFAULT -1,
  hash TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS passwords_user_id_index ON passwords (user_id);

CREATE TABLE emails (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  user_id BIGINT,
  data JSONB NOT NULL,
  hash SMALLINT NOT NULL,
  verified BOOL DEFAULT FALSE,
  recovery BOOL DEFAULT FALSE,
  active BOOL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS emails_user_id_index ON emails (user_id);
CREATE INDEX IF NOT EXISTS emails_hash_index ON emails (hash);

CREATE TABLE channels (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  handle TEXT NOT NULL,
  dname TEXT NOT NULL,
  bio TEXT,
  active BOOLEAN DEFAULT FALSE,
  listed BOOLEAN DEFAULT FALSE,
  public BOOLEAN DEFAULT FALSE,
  avatar TEXT,
  banner TEXT,
  creator_id BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS channels_active_index ON channels (active);
ALTER TABLE channels ADD CONSTRAINT channels_handle_length CHECK (char_length(handle) > 2 OR (char_length(handle) = 0 OR active IS FALSE OR handle IS NULL));
  -- first character must be letter, last character must not be dash or underscore
ALTER TABLE channels ADD CONSTRAINT channels_handle_regex CHECK (handle ~ '^[a-zA-Z][a-zA-Z0-9_\-]+[a-zA-Z0-9]$' OR active IS FALSE);
CREATE UNIQUE INDEX channels_handle_unique_lowercase ON channels (lower(handle)) WHERE (char_length(handle) > 2 AND active IS TRUE);

CREATE TABLE channelmemberships (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  channel_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  rank SMALLINT NOT NULL DEFAULT 0,
  banned BOOLEAN NOT NULL DEFAULT FALSE,
  hidden_at TIMESTAMPTZ,
  follow BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS channelmemberships_channel_id_user_id_unique ON channelmemberships (channel_id, user_id);
CREATE INDEX IF NOT EXISTS channelmemberships_channel_id_index ON channelmemberships (channel_id);
CREATE INDEX IF NOT EXISTS channelmemberships_user_id_index ON channelmemberships (user_id);
CREATE INDEX IF NOT EXISTS channelmemberships_user_id_follow_index ON channelmemberships (user_id, follow, channel_id);
CREATE INDEX IF NOT EXISTS channelmemberships_user_id_hidden_at_index ON channelmemberships (user_id, hidden_at, channel_id);
CREATE INDEX IF NOT EXISTS channelmemberships_user_id_rank_index ON channelmemberships (user_id, rank, channel_id);

CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  channel_id BIGINT NOT NULL,
  parent_id BIGINT,
  creator_id BIGINT,
  title TEXT,
  tags TEXT,
  url TEXT,
  link_id BIGINT,
  body_md TEXT,
  body_html TEXT,
  score INTEGER NOT NULL DEFAULT 0,
  replies SMALLINT NOT NULL DEFAULT 0,
  mask SMALLINT DEFAULT 0,
  cc_i16 SMALLINT NOT NULL,
  ip INET NOT NULL,
  active BOOLEAN NOT NULL DEFAULT FALSE,
  locked BOOLEAN NOT NULL DEFAULT FALSE,
  dead BOOLEAN NOT NULL DEFAULT FALSE,
  draft BOOLEAN NOT NULL DEFAULT TRUE,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS posts_active_index ON posts (active);
CREATE INDEX IF NOT EXISTS posts_link_id_index ON posts (link_id);
CREATE INDEX IF NOT EXISTS posts_channel_id_index ON posts (channel_id);
CREATE INDEX IF NOT EXISTS posts_creator_id_index ON posts (creator_id);
CREATE INDEX IF NOT EXISTS posts_mask_creator_id_index ON posts (mask, creator_id);

CREATE TABLE links (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  domain_id BIGINT NOT NULL ,
  url TEXT NOT NULL,
  meta JSONB,
  active BOOLEAN NOT NULL DEFAULT FALSE,
  lastseen_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS links_url_unique ON links (url);

CREATE INDEX IF NOT EXISTS links_active_index ON links (active);
CREATE INDEX IF NOT EXISTS links_lastseen_at_index ON links (lastseen_at);
CREATE INDEX IF NOT EXISTS links_domain_id_index ON links (domain_id);
CREATE INDEX IF NOT EXISTS links_youtube_id_null_index ON links ((meta ->> 'youtube_id')) WHERE ((meta ->> 'youtube_id') IS NOT NULL);

CREATE TABLE domains (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  domain TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT FALSE,
  parent_id BIGINT,
  lastseen_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS domains_domain_unique ON domains (domain);

CREATE INDEX IF NOT EXISTS domains_active_index ON domains (active);
CREATE INDEX IF NOT EXISTS domains_lastseen_at_index ON domains (lastseen_at);
CREATE INDEX IF NOT EXISTS domains_parent_id_index ON domains (parent_id);

CREATE TABLE postusers (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  post_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  vote SMALLINT,
  updated_at TIMESTAMPTZ,
  saved_at TIMESTAMPTZ,
  hidden_at TIMESTAMPTZ,
  flagged_at TIMESTAMPTZ,
  voted_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ -- when you last viewed the thread
);
CREATE UNIQUE INDEX IF NOT EXISTS postusers_post_id_user_id_unique ON postusers (post_id, user_id);
CREATE INDEX IF NOT EXISTS postusers_post_id_index ON postusers (post_id);
CREATE INDEX IF NOT EXISTS postusers_user_id_index ON postusers (user_id);
CREATE INDEX IF NOT EXISTS postusers_user_id_saved_at_index ON postusers (user_id, saved_at);
CREATE INDEX IF NOT EXISTS postusers_user_id_hidden_at_index ON postusers (user_id, hidden_at);

CREATE TABLE commentusers (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  comment_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  vote SMALLINT,
  collapsed BOOLEAN, -- user clicked collapse, or uncollapsed
  updated_at TIMESTAMPTZ,
  saved_at TIMESTAMPTZ,
  hidden_at TIMESTAMPTZ, -- placeholder, might remove later
  flagged_at TIMESTAMPTZ,
  voted_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ -- placeholder, maybe for marking replies read
);
CREATE UNIQUE INDEX IF NOT EXISTS commentusers_comment_id_user_id_unique ON commentusers (comment_id, user_id);
CREATE INDEX IF NOT EXISTS commentusers_comment_id_index ON commentusers (comment_id);
CREATE INDEX IF NOT EXISTS commentusers_user_id_index ON commentusers (user_id);
CREATE INDEX IF NOT EXISTS commentusers_user_id_saved_at_index ON commentusers (user_id, saved_at);

CREATE TABLE invitecodes (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  code TEXT NOT NULL,
  inviter_id BIGINT NOT NULL,
  redeemer_id BIGINT,
  redeemed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS invitecodes_code_unique ON invitecodes (code);
CREATE INDEX IF NOT EXISTS invitecodes_inviter_id_index ON invitecodes (inviter_id);
CREATE INDEX IF NOT EXISTS invitecodes_redeemer_id_index ON invitecodes (redeemer_id);

CREATE TABLE loginattempts (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  handle TEXT,
  cc_i16 SMALLINT NOT NULL,
  ip INET,
  success BOOLEAN,
  ua_id BIGINT,
  created_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS loginattempts_handle_ip_created_at_index ON loginattempts (handle, ip, created_at);
CREATE INDEX IF NOT EXISTS loginattempts_ip_handle_created_at_index ON loginattempts (ip, handle, created_at);

CREATE TABLE requestlogs (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  path_with_query TEXT,
  cc_i16 SMALLINT NOT NULL,
  ip INET,
  referer_id BIGINT,
  ua_id BIGINT,
  duration SMALLINT,
  user_id BIGINT,
  created_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS requestlogs_user_id_index ON requestlogs (user_id);
CREATE INDEX IF NOT EXISTS requestlogs_ip_index ON requestlogs (ip);
CREATE INDEX IF NOT EXISTS requestlogs_cc_i16_index ON requestlogs (cc_i16);

CREATE TABLE useragents (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  value TEXT NOT NULL,
  lastseen_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS useragents_value_unique ON useragents (value);

CREATE TABLE ipaddresses (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  value INET NOT NULL,
  lastseen_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS ipaddresses_value_unique ON ipaddresses (value);

CREATE TABLE referers (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  value TEXT NOT NULL,
  lastseen_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS referers_value_unique ON referers (value);

CREATE TABLE mimes (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  value TEXT NOT NULL,
  lastseen_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS mimes_value_unique ON mimes (value);

CREATE TABLE tags (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  value TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  lastseen_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS tags_value_unique ON tags (value);

CREATE TABLE post_tag (post_id BIGINT, tag_id BIGINT);
CREATE UNIQUE INDEX IF NOT EXISTS post_tag_value_unique ON post_tag (post_id, tag_id);
CREATE INDEX IF NOT EXISTS post_tag_post_id_index ON post_tag (post_id);
CREATE INDEX IF NOT EXISTS post_tag_tag_id_index ON post_tag (tag_id);

CREATE TABLE comments (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  channel_id BIGINT NOT NULL,
  post_id BIGINT NOT NULL,
  parent_id BIGINT,
  creator_id BIGINT,
  -- tags TEXT NOT NULL,
  body_md TEXT NOT NULL,
  body_html TEXT NOT NULL,
  score INTEGER NOT NULL DEFAULT 0,
  replies SMALLINT NOT NULL DEFAULT 0,
  mask SMALLINT DEFAULT 0,
  cc_i16 SMALLINT NOT NULL,
  ip INET NOT NULL,
  active BOOLEAN NOT NULL DEFAULT FALSE,
  locked BOOLEAN NOT NULL DEFAULT FALSE,
  dead BOOLEAN NOT NULL DEFAULT FALSE,
  draft BOOLEAN NOT NULL DEFAULT TRUE,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS comments_active_index ON comments (active);
CREATE INDEX IF NOT EXISTS comments_post_id_index ON comments (post_id);
CREATE INDEX IF NOT EXISTS comments_channel_id_index ON comments (channel_id);
CREATE INDEX IF NOT EXISTS comments_creator_id_index ON comments (creator_id);
CREATE INDEX IF NOT EXISTS comments_mask_creator_id_index ON comments (mask, creator_id);

CREATE TABLE channellogs (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  user_id BIGINT,
  channel_id BIGINT,
  post_id BIGINT,
  comment_id BIGINT,
  action SMALLINT,
  data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS channellogs_user_id_index ON channellogs (user_id);
CREATE INDEX IF NOT EXISTS channellogs_channel_id_index ON channellogs (channel_id);
CREATE INDEX IF NOT EXISTS channellogs_post_id_index ON channellogs (post_id);
CREATE INDEX IF NOT EXISTS channellogs_comment_id_index ON channellogs (comment_id);
CREATE INDEX IF NOT EXISTS channellogs_channel_id_action_index ON channellogs (channel_id, action);
CREATE INDEX IF NOT EXISTS channellogs_channel_id_user_id_index ON channellogs (channel_id, user_id);
CREATE INDEX IF NOT EXISTS channellogs_action_index ON channellogs (action);

CREATE TABLE channeljobs (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  user_id BIGINT,
  channel_id BIGINT,
  post_id BIGINT,
  comment_id BIGINT,
  action SMALLINT,
  data JSONB,
  run_at TIMESTAMPTZ,
  queued BOOLEAN,
  created_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS channeljobs_user_id_index ON channeljobs (user_id);
CREATE INDEX IF NOT EXISTS channeljobs_channel_id_index ON channeljobs (channel_id);
CREATE INDEX IF NOT EXISTS channeljobs_post_id_index ON channeljobs (post_id);
CREATE INDEX IF NOT EXISTS channeljobs_comment_id_index ON channeljobs (comment_id);
CREATE INDEX IF NOT EXISTS channeljobs_channel_id_action_index ON channeljobs (channel_id, action);
CREATE INDEX IF NOT EXISTS channeljobs_channel_id_user_id_index ON channeljobs (channel_id, user_id);
CREATE INDEX IF NOT EXISTS channeljobs_action_index ON channellogs (action);

CREATE TABLE uploads (
  id BIGSERIAL PRIMARY KEY NOT NULL,
  creator_id BIGINT,
  ip INET,
  ua_id BIGINT,
  mime_id BIGINT,
  size BIGINT,
  width SMALLINT,
  height SMALLINT,
  crc32 BIGINT,
  status SMALLINT,
  filename TEXT,
  typedesc TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS uploads_creator_id_index ON uploads (creator_id);
CREATE INDEX IF NOT EXISTS uploads_ip_index ON uploads (ip);
CREATE INDEX IF NOT EXISTS uploads_ua_id_index ON uploads (ua_id);
