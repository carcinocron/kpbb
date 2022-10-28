module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044455_create_appsettingskv_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.appsettingskv (
          k TEXT NOT NULL,
          v TEXT NOT NULL
        );
        CREATE UNIQUE INDEX appsettingskv_k_unique ON appsettingskv (k);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.appsettingskv;
      SQL
    end
  end
end
