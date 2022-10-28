@[Kpbb::Orm::Table(from: "users")]
struct Kpbb::PolicyUser
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_http_env("user_id")
  @@table = "users"

  def self.select_columns : Array(String)
    ["id", "active", "rank", "trust", "created_at"]
  end

  property id : Int64
  property active : Bool
  property rank : Int16
  property trust : Int16
  property created_at : Time

  def initialize(
    @id : Int64,
    @active : Bool,
    @rank : Int16,
    @trust : Int16,
    @created_at : Time
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @active = rs.read(Bool)
    @rank = rs.read(Int16)
    @trust = rs.read(Int16)
    @created_at = rs.read(Time)
  end
end
