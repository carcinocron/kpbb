module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044458_create_channels_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.channels (
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
        ALTER TABLE channels ADD CONSTRAINT channels_handle_regex CHECK (handle ~ '^[a-zA-Z][a-zA-Z0-9_-]+[a-zA-Z0-9]$' OR active IS FALSE);
        CREATE UNIQUE INDEX channels_handle_unique_lowercase ON channels (lower(handle)) WHERE (char_length(handle) > 2 AND active IS TRUE);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.channels;
      SQL
    end
  end
end
