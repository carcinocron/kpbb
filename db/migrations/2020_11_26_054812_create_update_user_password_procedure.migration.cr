module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_054812_create_update_user_password_procedure < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        DROP PROCEDURE IF EXISTS update_user_password;
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
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP PROCEDURE IF EXISTS update_user_password;
      SQL
    end
  end
end
