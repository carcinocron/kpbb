module Iom::Cli::DB::Migrations
  class Migration_2021_01_06_234416_alter_feed_endpoints_add_default_body_column < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        ALTER TABLE feed_inbound.endpoints ADD COLUMN IF NOT EXISTS default_body JSONB;
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        ALTER TABLE feed_inbound.endpoints DROP COLUMN IF EXISTS default_body JSONB;
      SQL
    end
  end
end
