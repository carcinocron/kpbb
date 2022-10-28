module Iom::Cli::DB::Migrations
  class Migration_2021_01_02_230742_alter_webhook_endpoints_add_lastposted_at_nextpost_at_columns < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        ALTER TABLE webhook_inbound.endpoints ADD COLUMN IF NOT EXISTS lastposted_at TIMESTAMPTZ;
        ALTER TABLE webhook_inbound.endpoints ADD COLUMN IF NOT EXISTS nextpost_at TIMESTAMPTZ;
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        ALTER TABLE webhook_inbound.endpoints DROP COLUMN IF EXISTS lastposted_at TIMESTAMPTZ;
        ALTER TABLE webhook_inbound.endpoints DROP COLUMN IF EXISTS nextpost_at TIMESTAMPTZ;
      SQL
    end
  end
end
