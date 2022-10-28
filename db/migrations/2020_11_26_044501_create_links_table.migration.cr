module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044501_create_links_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.links (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          domain_id BIGINT NOT NULL,
          url TEXT NOT NULL,
          url_abbr TEXT,
          meta JSONB,
          active BOOLEAN NOT NULL DEFAULT FALSE,
          lastseen_at TIMESTAMPTZ DEFAULT NOW(),
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        CREATE UNIQUE INDEX IF NOT EXISTS links_url_unique ON links (url);

        CREATE INDEX IF NOT EXISTS links_active_index ON links (active);
        CREATE INDEX IF NOT EXISTS links_lastseen_at_index ON links (lastseen_at);
        CREATE INDEX IF NOT EXISTS links_domain_id_index ON links (domain_id);
        CREATE INDEX IF NOT EXISTS links_youtube_id_null_index ON links ((meta ->> 'youtube_id')) WHERE ((meta ->> 'youtube_id') IS NOT NULL);
        CREATE INDEX IF NOT EXISTS links_url_abbr_index ON links (url_abbr);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.links;
      SQL
    end
  end
end
