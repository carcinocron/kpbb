require "pg"
require "option_parser"
require "../sh/cli_shared"
require "../db/migrations/*"

step = nil
dry_run = false
verbose = false
parser = ::OptionParser.new do |parser|
  parser.banner = "Usage: sh/migrate_up --env=.env --step=1"
  read_env
  parser.on("-v", "--verbose", "Enable verbose output") { verbose = true }
  # parser.on("", "--dry-run", "Dry Run") { dry_run = true }
  parser.on("", "--step=STEP", "Enable verbose output") { |new_value| step = new_value.to_i }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit(0)
  end
  parser.missing_option do |missing_option|
    next if missing_option == "--env"
    pp ({:missing_option => missing_option})
    exit(1)
  end
  parser.invalid_option do |invalid_option|
    pp ({:invalid_option => invalid_option})
    exit(1)
  end
end

parser.parse

# pp ({:line => __LINE__, :dry_run => dry_run, :step => step})
# pp ({:PG_URL => ENV["PG_URL"]})

module Iom::Cli::DB::MigrationRunner
  def self.run(db : ::DB::Database) : Nil
    ::Iom::Cli::DB::MigrationRow.create_table_if_not_exists(db)
    rows = ::Iom::Cli::DB::MigrationRow.all(db)
    migrations = Iom::Cli::DB::MigrationRunner.migrations(db)
    batch = (rows.map(&.batch)[0]? || 0) + 1

    migrations.each do |migration|
      next if rows.select { |row| row.migration == migration.migration_key }.size > 0
      puts "migrating #{migration.migration_key}"
      migration.up
      MigrationRow.insert(db, migration.migration_key, batch)
      puts " \xE2\x9C\x94 migrated #{migration.migration_key}"
    end
    # pp migrations.map(&.migration_key)
  end
end

db = PG.connect ENV["PG_URL"]

Iom::Cli::DB::MigrationRunner.run(db)

STDOUT << "finished migrations"
# pp ({:line => __LINE__})
