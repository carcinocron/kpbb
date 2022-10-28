module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044514_create_uploads_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.uploads (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          creator_id BIGINT,
          ip INET,
          ua_id BIGINT,
          mime_id BIGINT,
          size BIGINT,
          width SMALLINT,
          height SMALLINT,
          crc32 BIGINT,
          status SMALLINT,
          filename TEXT,
          typedesc TEXT,
          created_at TIMESTAMPTZ,
          updated_at TIMESTAMPTZ
        );
        CREATE INDEX IF NOT EXISTS uploads_creator_id_index ON uploads (creator_id);
        CREATE INDEX IF NOT EXISTS uploads_ip_index ON uploads (ip);
        CREATE INDEX IF NOT EXISTS uploads_ua_id_index ON uploads (ua_id);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.uploads;
      SQL
    end
  end
end
