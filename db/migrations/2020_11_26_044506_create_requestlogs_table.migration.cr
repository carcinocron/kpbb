module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044506_create_requestlogs_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.requestlogs (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          path_with_query TEXT,
          cc_i16 SMALLINT,
          ip INET,
          referer_id BIGINT,
          ua_id BIGINT,
          duration SMALLINT,
          user_id BIGINT,
          created_at TIMESTAMPTZ
        );
        CREATE INDEX IF NOT EXISTS requestlogs_user_id_index ON requestlogs (user_id);
        CREATE INDEX IF NOT EXISTS requestlogs_ip_index ON requestlogs (ip);
        CREATE INDEX IF NOT EXISTS requestlogs_cc_i16_index ON requestlogs (cc_i16);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.requestlogs;
      SQL
    end
  end
end
