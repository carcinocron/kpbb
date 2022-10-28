module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044508_create_ipaddresses_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.ipaddresses (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          value INET NOT NULL,
          lastseen_at TIMESTAMPTZ,
          created_at TIMESTAMPTZ
        );
        CREATE UNIQUE INDEX IF NOT EXISTS ipaddresses_value_unique ON ipaddresses (value);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.ipaddresses;
      SQL
    end
  end
end
