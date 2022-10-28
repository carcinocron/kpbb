module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044507_create_useragents_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.useragents (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          value TEXT NOT NULL,
          lastseen_at TIMESTAMPTZ,
          created_at TIMESTAMPTZ
        );
        CREATE UNIQUE INDEX IF NOT EXISTS useragents_value_unique ON useragents (value);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.useragents;
      SQL
    end
  end
end
