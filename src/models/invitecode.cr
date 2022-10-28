require "random/secure"

@[Kpbb::Orm::Table(from: "invitecodes")]
struct Kpbb::Invitecode
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  @@table = "invitecodes"

  def self.select_columns : Array(String)
    ["id", "inviter_id", "code", "redeemer_id", "redeemed_at", "created_at"]
  end

  property id : Int64
  property inviter_id : Int64
  property code : String
  property redeemer_id : Int64?
  property redeemed_at : Time?
  property created_at : Time

  def initialize(@id : Int64, @inviter_id : Int64, @code : String, @redeemer_id : Int64?, @redeemed_at : Time?, @created_at : Time)
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @inviter_id = rs.read(Int64)
    @code = rs.read(String)
    @redeemer_id = rs.read(Int64?)
    @redeemed_at = rs.read(Time?)
    @created_at = rs.read(Time)
  end

  def self.make(inviter_id : Int64) : self
    self.new(inviter_id: inviter_id, code: Random::Secure.urlsafe_base64(40))
  end

  def self.find_by_code!(code : String) : self
    begin
      rs = Kpbb.db.query_one("SELECT #{self.select} FROM #{@@table} WHERE code = $1 LIMIT 1", args: [
        code,
      ]) do |rs|
        return self.new(rs)
      end
    end
  end

  def self.find_by_code?(code : String) : self?
    begin
      rs = Kpbb.db.query_one("SELECT #{self.select} FROM #{@@table} WHERE code = $1 LIMIT 1", args: [
        code,
      ]) do |rs|
        return self.new(rs)
      end
    rescue ex : DB::NoResultsError
      nil
    end
    nil
  end

  def self.find!(env : HTTP::Server::Context) : self
    return self.find! env.params.url["invitecode_id"].to_i64_from_b62? if env.params.url.has_key? "invitecode_id"
    return self.find_by_code! env.params.url["invitecode"]? || ""
  end

  def self.find?(env : HTTP::Server::Context) : self?
    return self.find? env.params.url["invitecode_id"].to_i64_from_b62? if env.params.url.has_key? "invitecode_id"
    return self.find_by_code? env.params.url["invitecode"]? || ""
  end

  def self.required? : Bool
    required = Kpbb.db.query_one(INVITECODE_REQUIRED_QUERY, as: {Bool})
  end
end

private INVITECODE_REQUIRED_QUERY = "SELECT EXISTS(
  SELECT 1 FROM appsettingskv WHERE k = 'register_require_invitecode' AND v = '1'
) as required"
