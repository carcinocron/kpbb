# when the first id is 1000
# the first in base62 is "g8"

Kpbb.db.exec <<-SQL
CREATE OR REPLACE FUNCTION empty_db_for_tests()
RETURNS void AS $$
  DELETE FROM webhook_inbound_payloads;
  ALTER SEQUENCE webhook_inbound_payloads_id_seq RESTART WITH 1000;
  DELETE FROM webhook_inbound_endpoints;
  ALTER SEQUENCE webhook_inbound_endpoints_id_seq RESTART WITH 1000;

  DELETE FROM feed_inbound_payloads;
  ALTER SEQUENCE feed_inbound_payloads_id_seq RESTART WITH 1000;
  DELETE FROM feed_inbound_endpoints;
  ALTER SEQUENCE feed_inbound_endpoints_id_seq RESTART WITH 1000;

  DELETE FROM youtube_video_snippets;
  DELETE FROM youtube_channel_snippets;

  -- DELETE FROM flair.bots;
  -- ALTER SEQUENCE flair.bots_id_seq RESTART WITH 1000;
  -- DELETE FROM flair.item;
  -- ALTER SEQUENCE flair.item_id_seq RESTART WITH 1000;
  -- DELETE FROM flair.post;

  DELETE FROM uploads;
  ALTER SEQUENCE uploads_id_seq RESTART WITH 1000;
  DELETE FROM channellogs;
  ALTER SEQUENCE channellogs_id_seq RESTART WITH 1000;
  DELETE FROM channeljobs;
  ALTER SEQUENCE channeljobs_id_seq RESTART WITH 1000;
  DELETE FROM post_tag;
  DELETE FROM postusers;
  DELETE FROM posts;
  ALTER SEQUENCE posts_id_seq RESTART WITH 1000;
  DELETE FROM links;
  ALTER SEQUENCE links_id_seq RESTART WITH 1000;
  DELETE FROM domains;
  ALTER SEQUENCE domains_id_seq RESTART WITH 1000;
  DELETE FROM passwords;
  ALTER SEQUENCE passwords_id_seq RESTART WITH 1000;
  DELETE FROM emails;
  ALTER SEQUENCE emails_id_seq RESTART WITH 1000;
  DELETE FROM users;
  ALTER SEQUENCE users_id_seq RESTART WITH 1000;
  DELETE FROM channelmemberships;
  ALTER SEQUENCE channelmemberships_id_seq RESTART WITH 1000;
  DELETE FROM channels;
  ALTER SEQUENCE channels_id_seq RESTART WITH 1000;
  DELETE FROM sessions;
  -- ALTER SEQUENCE sessions_id_seq RESTART WITH 1000;
  DELETE FROM appsettingskv;
  -- ALTER SEQUENCE appsettingskv_id_seq RESTART WITH 1000;
  DELETE FROM invitecodes;
  ALTER SEQUENCE invitecodes_id_seq RESTART WITH 1000;
  DELETE FROM loginattempts;
  ALTER SEQUENCE loginattempts_id_seq RESTART WITH 1000;
  DELETE FROM requestlogs;
  ALTER SEQUENCE requestlogs_id_seq RESTART WITH 1000;
  DELETE FROM useragents;
  ALTER SEQUENCE useragents_id_seq RESTART WITH 1000;
  DELETE FROM referers;
  ALTER SEQUENCE referers_id_seq RESTART WITH 1000;
  DELETE FROM ipaddresses;
  ALTER SEQUENCE ipaddresses_id_seq RESTART WITH 1000;
  DELETE FROM tags;
  ALTER SEQUENCE tags_id_seq RESTART WITH 1000;
  DELETE FROM mimes;
  ALTER SEQUENCE mimes_id_seq RESTART WITH 1000;
$$
LANGUAGE SQL;
SQL

def empty_db
  Kpbb.db.exec "SELECT empty_db_for_tests()"
end

# @todo is bulk setval faster?
# Kpbb.db.exec "SELECT SETVAL('ipaddresses_id_seq', 1), SETVAL('channels_id_seq', 1)"
