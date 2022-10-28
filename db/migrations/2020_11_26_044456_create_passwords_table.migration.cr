module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044456_create_passwords_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.passwords (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          user_id BIGINT,
          strength SMALLINT DEFAULT -1,
          hash TEXT,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS passwords_user_id_index ON passwords (user_id);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.passwords;
      SQL
    end
  end
end
