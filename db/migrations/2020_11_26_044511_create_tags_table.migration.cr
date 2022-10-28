module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044511_create_tags_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.tags (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          value TEXT NOT NULL,
          active BOOLEAN NOT NULL DEFAULT TRUE,
          lastseen_at TIMESTAMPTZ,
          created_at TIMESTAMPTZ
        );
        CREATE UNIQUE INDEX IF NOT EXISTS tags_value_unique ON tags (value);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.tags;
      SQL
    end
  end
end
