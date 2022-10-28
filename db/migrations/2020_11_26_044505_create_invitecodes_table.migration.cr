module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_044505_create_invitecodes_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.invitecodes (
          id BIGSERIAL PRIMARY KEY NOT NULL,
          code TEXT NOT NULL,
          inviter_id BIGINT NOT NULL,
          redeemer_id BIGINT,
          redeemed_at TIMESTAMPTZ,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE UNIQUE INDEX IF NOT EXISTS invitecodes_code_unique ON invitecodes (code);
        CREATE INDEX IF NOT EXISTS invitecodes_inviter_id_index ON invitecodes (inviter_id);
        CREATE INDEX IF NOT EXISTS invitecodes_redeemer_id_index ON invitecodes (redeemer_id);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.invitecodes;
      SQL
    end
  end
end
