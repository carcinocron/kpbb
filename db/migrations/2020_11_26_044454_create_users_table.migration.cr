module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044454_create_users_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.users (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          handle TEXT NOT NULL,
          dname TEXT NOT NULL,
          pronouns TEXT,
          lang TEXT,
          pw_id BIGINT,
          mfa_id BIGINT,
          avatar TEXT,
          banner TEXT,
          bio TEXT,
          active BOOLEAN DEFAULT FALSE,
          rank SMALLINT,
          trust SMALLINT,
          theme_id SMALLINT,
          lastlogin_at TIMESTAMPTZ,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS users_active_index ON users (active);
        ALTER TABLE users ADD CONSTRAINT users_handle_length CHECK (char_length(handle) > 2);
          -- first character must be letter, last character must not be dash or underscore
        ALTER TABLE users ADD CONSTRAINT users_handle_regex CHECK (handle ~ '^[a-zA-Z][a-zA-Z0-9_-]+[a-zA-Z0-9]$');
        CREATE UNIQUE INDEX users_handle_unique_lowercase ON users (lower(handle));
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.create_users_table;
      SQL
    end
  end
end
