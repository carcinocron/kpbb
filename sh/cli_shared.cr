DB_MIGRATION_PATH   = "db/migrations"
DB_MIGRATIONS_TABLE = "public.migrations"

class Iom::Cli::DB::MigrationRow
  getter id : Int64
  getter migration : String
  getter batch : Int16
  getter created_at : Time

  def initialize(rs : ::DB::ResultSet)
    @id = rs.read(typeof(@id))
    @migration = rs.read(typeof(@migration))
    @batch = rs.read(typeof(@batch))
    @created_at = rs.read(typeof(@created_at))
  end

  def self.create_table_if_not_exists(db : ::DB::Database)
    db.exec <<-SQL
      CREATE TABLE IF NOT EXISTS #{DB_MIGRATIONS_TABLE} (
        id BIGSERIAL PRIMARY KEY NOT NULL,
        migration TEXT NOT NULL UNIQUE,
        batch SMALLINT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    SQL
  end

  def self.all(db : ::DB::Database)
    sql = <<-SQL
      SELECT id, migration, batch, created_at
      FROM #{DB_MIGRATIONS_TABLE}
      ORDER BY id ASC;
    SQL
    rows = Array(self).new
    db.query sql do |rs|
      rs.each do
        rows << self.new(rs)
      end
    end
    rows
  end

  def self.insert(db : ::DB::Database, migration : String, batch : Int)
    sql = <<-SQL
      INSERT INTO #{DB_MIGRATIONS_TABLE}
      (migration, batch, created_at)
      VALUES ($1, $2, NOW());
    SQL
    result = db.exec sql, args: [migration, batch]
    pp result
  end
end

abstract class Iom::Cli::DB::Migration
  def initialize(@db : ::DB::Database)
  end

  @@migration_key : String? = nil

  def up : Nil
  end

  def down : Nil
  end

  def migration_key : String
    @@migration_key ||= self.class.name["Iom::Cli::DB::Migrations::Migration_".size..]
  end

  def unprepared(sql)
    @db.using_connection do |conn|
      conn.exec_all sql
    end
  end
end

macro read_env
  parser.on("-e ENV", "--env=ENV", "Read .env file") do |name|
    pp ({:name => name})
    # puts parser
    File.each_line(name) do |line|
      next unless line.size > 0
      next if line[0] == '#'
      next if line[0] == ' '
      next unless (index = line.index('='))
      next unless (key = line[0..index-1].presence)
      next unless (value = line[(index+1)..].presence)
      ENV[key] = value
    end
  end
end
