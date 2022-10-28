module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044504_create_loginattempts_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.loginattempts (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          handle TEXT,
          cc_i16 SMALLINT,
          ip INET,
          success BOOLEAN,
          ua_id BIGINT,
          created_at TIMESTAMPTZ
        );
        CREATE INDEX IF NOT EXISTS loginattempts_handle_ip_created_at_index ON loginattempts (handle, ip, created_at);
        CREATE INDEX IF NOT EXISTS loginattempts_ip_handle_created_at_index ON loginattempts (ip, handle, created_at);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.loginattempts;
      SQL
    end
  end
end
