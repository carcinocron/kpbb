module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044457_create_emails_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.emails (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          user_id BIGINT,
          data JSONB NOT NULL,
          hash SMALLINT,
          verified BOOL DEFAULT FALSE,
          recovery BOOL DEFAULT FALSE,
          active BOOL DEFAULT FALSE,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS emails_user_id_index ON emails (user_id);
        CREATE INDEX IF NOT EXISTS emails_hash_index ON emails (hash);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.emails;
      SQL
    end
  end
end
