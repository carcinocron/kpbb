CREATE OR REPLACE FUNCTION test_insert_user(
    /*password hash :*/ TEXT,
    /*strength :*/ SMALLINT,
    /*handle :*/ TEXT,
    /*dname :*/ TEXT,
    /*bio :*/ TEXT,
    /*avatar :*/ TEXT,
    /*rank :*/ SMALLINT
    )
RETURNS TABLE (user_id BIGINT, pw_id BIGINT, created_at TIMESTAMP)
AS $$
DECLARE
    user_id BIGINT;
    pw_id BIGINT;
    at TIMESTAMP := NOW();
BEGIN

    WITH users AS (
      INSERT INTO users (
        handle, dname, pw_id, "bio", avatar, rank,
        lastlogin_at, updated_at, created_at
      )
      VALUES ($3, $4, null, $5, $6, &7, at, at, at)
      returning id
    ) SELECT users.id INTO user_id FROM users;

    WITH passwords AS (
      INSERT INTO passwords (user_id, hash, strength, created_at)
      VALUES (user_id, $1, $2, at)
      RETURNING id
    ) SELECT passwords.id INTO pw_id FROM passwords;

    UPDATE users
    SET pw_id = pw_id, updated_at = at
    WHERE id = user_id;

    COMMIT;

    SELECT user_id, pw_id, at;
END;
$$ LANGUAGE plpgsql;
