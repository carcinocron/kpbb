# autogenerated file!
module Iom::Cli::DB::MigrationRunner
  def self.migrations(db : ::DB::Database) : Array(::Iom::Cli::DB::Migration)
    return [
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044454_create_users_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044455_create_appsettingskv_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044456_create_passwords_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044457_create_emails_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044458_create_channels_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044459_create_channelmemberships_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044500_create_posts_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044501_create_links_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044502_create_domains_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044503_create_postusers_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044504_create_loginattempts_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044505_create_invitecodes_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044506_create_requestlogs_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044507_create_useragents_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044508_create_ipaddresses_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044509_create_referers_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044510_create_mimes_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044511_create_tags_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044512_create_channellogs_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044513_create_channeljobs_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_044514_create_uploads_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_051837_create_post_tag_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_054005_create_youtube_video_snippets_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_054006_create_youtube_channel_snippets_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_054348_create_webhook_inbound_endpoints_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_054349_create_webhook_inbound_payloads_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_054559_create_insert_requestlog_procedure.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_054812_create_update_user_password_procedure.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_230448_create_feed_inbound_endpoints_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_26_230454_create_feed_inbound_payloads_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_11_30_221901_alter_posts_add_ptype_column.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2020_12_11_023807_alter_posts_table_rename_active_to_posted.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2021_01_02_230741_alter_feed_endpoints_add_lastposted_at_nextpost_at_columns.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2021_01_02_230742_alter_webhook_endpoints_add_lastposted_at_nextpost_at_columns.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2021_01_06_234407_alter_webhook_endpoints_add_default_body_column.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2021_01_06_234416_alter_feed_endpoints_add_default_body_column.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2021_07_15_184019_create_youtube_channel_snippets_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2021_07_15_184607_create_youtube_video_snippets_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2021_07_15_202602_create_webhook_inbound_endpoints_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2021_07_15_202603_create_webhook_inbound_payloads_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2021_07_16_012427_create_feed_inbound_endpoints_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2021_07_16_012428_create_feed_inbound_payloads_table.new(db),
      ::Iom::Cli::DB::Migrations::Migration_2021_10_10_025705_create_discussion_links_table.new(db),
    ] of ::Iom::Cli::DB::Migration
  end
end
