module Iom::Cli::DB::Migrations
  class Migration_2020_12_11_023807_alter_posts_table_rename_active_to_posted < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        DROP INDEX IF EXISTS posts_active_index;
        ALTER TABLE public.posts RENAME active TO posted;
        CREATE INDEX IF NOT EXISTS posts_posted_index ON posts (posted);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP INDEX IF EXISTS posts_posted_index;
        ALTER TABLE public.posts RENAME posted TO active;
        CREATE INDEX IF NOT EXISTS posts_active_index ON posts (active);
      SQL
    end
  end
end
