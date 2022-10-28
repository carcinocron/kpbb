require "../request/registeruser"
require "../request/loginuser"

alias RedeemsInvitecode = (Kpbb::Request::RegisterUser)

class Kpbb::Validator::Invitecode < Accord::Validator
  def initialize(context : RedeemsInvitecode)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.invitecode.nil? || @context.invitecode == ""
      errors.add(:invitecode, "Invite code required.") if Kpbb::Invitecode.required?
      return
    end
    errors.add(:invitecode, "Invite code invalid.") unless invitecode_valid?
  end

  def invitecode_valid? : Bool
    valid = Kpbb.db.query_one(INVITECODE_VALID_QUERY, @context.invitecode.not_nil!, as: {Bool})
  end
end

private INVITECODE_VALID_QUERY = "SELECT EXISTS(
  SELECT 1 FROM invitecodes WHERE code = $1 AND redeemer_id IS NULL
) as valid"
