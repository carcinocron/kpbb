module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044502_create_domains_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.domains (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          domain TEXT NOT NULL,
          active BOOLEAN NOT NULL DEFAULT FALSE,
          parent_id BIGINT,
          lastseen_at TIMESTAMPTZ DEFAULT NOW(),
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        CREATE UNIQUE INDEX IF NOT EXISTS domains_domain_unique ON domains (domain);

        CREATE INDEX IF NOT EXISTS domains_active_index ON domains (active);
        CREATE INDEX IF NOT EXISTS domains_lastseen_at_index ON domains (lastseen_at);
        CREATE INDEX IF NOT EXISTS domains_parent_id_index ON domains (parent_id);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.domains;
      SQL
    end
  end
end
