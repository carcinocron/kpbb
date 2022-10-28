module Iom::Cli::DB::Migrations
  class Migration_2020_11_26_051837_create_post_tag_table < ::Iom::Cli::DB::Migration
    # apply changes to the DB
    def up : Nil
      unprepared <<-SQL
        CREATE TABLE public.post_tag (
          post_id BIGINT,
          tag_id BIGINT
        );
        CREATE UNIQUE INDEX IF NOT EXISTS post_tag_value_unique ON post_tag (post_id, tag_id);
        CREATE INDEX IF NOT EXISTS post_tag_post_id_index ON post_tag (post_id);
        CREATE INDEX IF NOT EXISTS post_tag_tag_id_index ON post_tag (tag_id);
      SQL
    end

    # revert changes to the DB
    def down : Nil
      unprepared <<-SQL
        DROP TABLE IF EXISTS public.post_tag;
      SQL
    end
  end
end
