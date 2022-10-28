module Iom::Cli::DB::Migrations
  class Migration_2021_10_10_025705_create_discussion_links_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.discussion_links (
          link_id BIGINT,
          dlink_id BIGINT
        );
        CREATE UNIQUE INDEX discussion_links_unique ON discussion_links (link_id, dlink_id);
        ALTER TABLE links ADD COLUMN IF NOT EXISTS discussions SMALLINT;
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.discussion_links;
      SQL
    end
  end
end