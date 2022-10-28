require "pg"
require "json"
# require "pool/connection"
require "./util/accord"
require "./models"
# require "./models/youtube/*"

# APP_DB =
#   PG_DB = ConnectionPool.new(capacity: 25, timeout: 0.1) do
#     ::PG.connect(ENV["PG_URL"])
#   end

# 2,147,483,647
PG_INTEGER_MAX = Int32::MAX
# 32,767
PG_SMALLINT_MAX = Int16::MAX

IS_DEBUG = ENV["APP_DEBUG"]? == "true"

module Kpbb
  @@db : DB::Database?

  def self.db
    @@db ||= PG.connect ENV["PG_URL"]
  end

  alias PGValue = ::PG::PGValue | Int64 | Int16
end

struct NextQuestionMark
  @current = 0

  def next : String
    "$#{(@current += 1)}"
  end
end

# PG_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S.%L %:z"
# struct Time
#   def to_db: String
#     self.to_utc.to_s PG_TIMESTAMP_FORMAT
#   end
# end

module Kpbb
end

# private struct Query
#   include JSON::Serializable
#   property query : String?
#   property bindings : Array?
# end

# #<AnyHash::JSON:0x7f6aae8c1620
#  @__hash__=
#   {:bindings => [1],
#    :query =>
#     "  SELECT users.id, users.handle, users.dname, users.bio, users.avatar, users.banner, users.pronouns FROM users\n" +
#     "  WHERE users.id IN ($1)",
#    :duration => "0 ms"}>
private macro debug_dump_query
  # if IS_DEBUG
  #   pp ({
  #     :query => bc.data[:query],
  #     :bindings => bc.data[:bindings],
  #     :duration => bc.data[:duration],
  #   })
  # end
end

module DB
  module QueryMethods(Stmt)
    def query(query, *args_, args : Array? = nil)
      bc = ::Raven::Breadcrumb.record(
        data: {:bindings => args || args_, :query => query},
        category: "db.query")
      start_at = Time.monotonic
      begin
        result = build(query).query(*args_, args: args)
      ensure
        bc.data[:duration] = (Time.monotonic - start_at).milliseconds.to_s + " ms"
        debug_dump_query
      end
      result
    end
  end

  # Performs the `query` and returns an `ExecResult`
  def exec(query, *args_, args : Array? = nil)
    bc = ::Raven::Breadcrumb.record(
      data: {:bindings => args || args_, :query => query},
      category: "db.query")
    start_at = Time.monotonic
    begin
      result = build(query).exec(*args_, args: args)
    ensure
      bc.data[:duration] = (Time.monotonic - start_at).milliseconds.to_s + " ms"
      debug_dump_query
    end
    result
  end

  # Performs the `query` and returns a single scalar value
  #
  # ```
  # puts db.scalar("SELECT MAX(name)").as(String) # => (a String)
  # ```
  def scalar(query, *args_, args : Array? = nil)
    bc = ::Raven::Breadcrumb.record(
      data: {:bindings => args || args_, :query => query},
      category: "db.query")
    start_at = Time.monotonic
    begin
      result = build(query).scalar(*args_, args: args)
    ensure
      bc.data[:duration] = (Time.monotonic - start_at).milliseconds.to_s + " ms"
      debug_dump_query
    end
    result
  end
end
