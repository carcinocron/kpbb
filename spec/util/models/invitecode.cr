struct TestInvitecode
  property id : Int64
  property inviter_id : Int64
  property code : String
  property redeemer_id : Int64?
  property redeemed_at : Time?
  property created_at : Time

  def initialize(
    @inviter_id : Int64,
    @code : String,
    @redeemer_id : Int64? = nil,
    @redeemed_at : Time? = nil
  )
    @id, @created_at = Kpbb.db.query_one(<<-SQL,
      INSERT INTO invitecodes (inviter_id, code, redeemer_id, redeemed_at, created_at)
      VALUES ($1, $2, $3, $4, NOW()) returning id, created_at
    SQL
      args: [
        @inviter_id,
        @code,
        @redeemer_id,
        @redeemed_at,
      ], as: {Int64, Time})
  end

  def initialize(@id : Int64)
    id, @inviter_id, @code, @redeemer_id, @redeemed_at, @created_at = Kpbb.db.query_one <<-SQL,
      SELECT id, inviter_id, code, redeemer_id, redeemed_at, created_at
      FROM invitecodes WHERE id = $1
    SQL
      args: [
        @id,
      ], as: {Int64, Int64, String, Int64?, Time?, Time}
  end
end
