CREATE OR REPLACE PROCEDURE update_user_password(
    /*user_id :*/ BIGINT,
    /*password hash :*/ TEXT,
    /*strength :*/ SMALLINT)
LANGUAGE plpgsql
AS $$
DECLARE
    new_pw_id BIGINT;
    at TIMESTAMP := NOW();
BEGIN
    WITH passwords AS (
      INSERT INTO passwords (user_id, hash, strength, created_at)
      VALUES ($1, $2, $3, at)
      RETURNING id
    ) SELECT passwords.id INTO new_pw_id FROM passwords;

    UPDATE users
    SET pw_id = new_pw_id, updated_at = at
    WHERE id = $1;

END;
$$;
