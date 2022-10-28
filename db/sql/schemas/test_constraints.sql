ALTER TABLE users ADD CONSTRAINT users_rank_not_null CHECK (rank IS NOT NULL);
ALTER TABLE users ADD CONSTRAINT users_trust_not_null CHECK (trust IS NOT NULL);
ALTER TABLE users ADD CONSTRAINT users_created_at_not_null CHECK (created_at IS NOT NULL);
ALTER TABLE users ADD CONSTRAINT users_updated_at_not_null CHECK (updated_at IS NOT NULL);
ALTER TABLE users ADD CONSTRAINT users_theme_id_not_null CHECK (theme_id IS NOT NULL);
-- ALTER TABLE posts ADD CONSTRAINT posts_cc_i16_length CHECK (char_length(cc_i16) = 2);
-- ALTER TABLE comments ADD CONSTRAINT comments_cc_i16_length CHECK (char_length(cc_i16) = 2);
-- ALTER TABLE requestlogs ADD CONSTRAINT requestlogs_cc_i16_length CHECK (char_length(cc_i16) = 2);
-- ALTER TABLE loginattempts ADD CONSTRAINT loginattempts_cc_i16_length CHECK (char_length(cc_i16) = 2);
-- ALTER TABLE webhook_inbound.payloads ADD CONSTRAINT webhook_inbound_payloads_cc_i16_length CHECK (char_length(cc_i16) = 2);
-- ALTER TABLE feed_inbound.payloads ADD CONSTRAINT feed_inbound_payloads_cc_i16_length CHECK (char_length(cc_i16) = 2);

-- ALTER TABLE posts ADD CONSTRAINT posts_ip_notnull CHECK (ip IS NOT NULL);
-- ALTER TABLE comments ADD CONSTRAINT comments_ip_notnull CHECK (ip IS NOT NULL);
-- ALTER TABLE requestlogs ADD CONSTRAINT requestlogs_ip_notnull CHECK (ip IS NOT NULL);
-- ALTER TABLE loginattempts ADD CONSTRAINT loginattempts_ip_notnull CHECK (ip IS NOT NULL);
-- ALTER TABLE webhook_inbound.payloads ADD CONSTRAINT webhooks_payloads_ip_notnull CHECK (ip IS NOT NULL);
-- ALTER TABLE feed_inbound.payloads ADD CONSTRAINT feed_payloads_ip_notnull CHECK (ip IS NOT NULL);

-- SELECT con.*
--        FROM pg_catalog.pg_constraint con
--             INNER JOIN pg_catalog.pg_class rel
--                        ON rel.oid = con.conrelid
--             INNER JOIN pg_catalog.pg_namespace nsp
--                        ON nsp.oid = connamespace
--        WHERE nsp.nspname = 'public'
--              AND rel.relname = 'requestlogs';
-- ALTER TABLE requestlogs DROP CONSTRAINT requestlogs_cc_i16_length;
-- ALTER TABLE requestlogs DROP CONSTRAINT requestlogs_ip_length;
