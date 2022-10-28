module Iom::Cli::DB::Migrations
  class Migration_2020_11_30_221901_alter_posts_add_ptype_column < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        ALTER TABLE public.posts ADD COLUMN ptype SMALLINT;
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        ALTER TABLE public.posts DROP COLUMN ptype;
      SQL
    end
  end
end
