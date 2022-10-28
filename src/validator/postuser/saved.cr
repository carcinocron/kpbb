require "../../request/channelmembership/upsert"

class Kpbb::Validator::PostUser::Saved < Accord::Validator
  def initialize(context : Kpbb::Request::PostUser::Upsert)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    return unless @context.input.has_key? "saved"
    if !@context.is_user
      errors.add(:saved, "You can't edit another user's post saved.")
      return
    end
  end
end
