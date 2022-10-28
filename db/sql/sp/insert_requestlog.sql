DROP PROCEDURE IF EXISTS insert_requestlog(text, text, text, text, text, integer, bigint);
DROP PROCEDURE IF EXISTS insert_requestlog(text, text, text, text, smallint, integer, bigint);
DROP PROCEDURE IF EXISTS insert_requestlog;
CREATE OR REPLACE PROCEDURE insert_requestlog(
    /*useragent :*/ TEXT,
    /*referer :*/ TEXT,
    /*ipaddress :*/ TEXT,
    /*path_with_query :*/ TEXT,
    /*cc_i16 :*/ SMALLINT,
    /*duration :*/ INTEGER,
    /*user_id :*/ BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    ua_id BIGINT;
    referer_id BIGINT;
    ip_id BIGINT;
    ipaddress INET := $3::INET;
    -- blank TEXT := '';
BEGIN
    IF ($1 IS NOT NULL AND $1 != '') THEN
      WITH useragents AS (
        INSERT INTO useragents (value, lastseen_at, created_at) VALUES ($1, NOW(), NOW())
        ON CONFLICT (value) DO UPDATE SET lastseen_at = excluded.lastseen_at
        RETURNING id
      ) SELECT useragents.id INTO ua_id FROM useragents;
    ELSE
      ua_id := NULL;
    END IF;

    IF ($2 IS NOT NULL AND $2 != '') THEN
      WITH referers AS (
        INSERT INTO referers (value, lastseen_at, created_at) VALUES ($2, NOW(), NOW())
        ON CONFLICT (value) DO UPDATE SET lastseen_at = excluded.lastseen_at
        RETURNING id
      ) SELECT referers.id INTO referer_id FROM referers;
    ELSE
      referer_id := NULL;
    END IF;

    IF (ipaddress IS NOT NULL AND $3 != '') THEN
      WITH ipaddresses AS (
        INSERT INTO ipaddresses (value, lastseen_at, created_at) VALUES (ipaddress, NOW(), NOW())
        ON CONFLICT (value) DO UPDATE SET lastseen_at = excluded.lastseen_at
        RETURNING id
      ) SELECT ipaddresses.id INTO ip_id FROM ipaddresses;
    ELSE
      ip_id := NULL;
    END IF;

    INSERT INTO requestlogs (
      path_with_query, cc_i16, duration, user_id, ip, referer_id, ua_id, created_at
    ) VALUES (
      $4, $5, $6, $7, ipaddress, referer_id, ua_id, NOW()
    );

    COMMIT;
END;
$$;
