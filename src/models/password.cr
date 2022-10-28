@[Kpbb::Orm::Table(from: "passwords")]
struct Kpbb::Password
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_bigint_id_via_foreignkey(userpw_id, users, pw_id)
  # Kpbb::Util::Model.find_by_http_env("password_id")
  @@table = "passwords"

  def self.select_columns : Array(String)
    ["id", "user_id", "hash", "strength", "created_at"]
  end

  property id : Int64
  property user_id : Int64
  property hash : String
  property strength : Int16
  property created_at : Time

  def initialize(
    @id : Int64,
    @user_id : Int64,
    @hash : String,
    @strength : Int16,
    @created_at : Time
  )
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @user_id = rs.read(Int64)
    @hash = rs.read(String)
    @strength = rs.read(Int16)
    @created_at = rs.read(Time)
  end
end
