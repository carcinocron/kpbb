require "../../request/channelmembership/upsert"

class Kpbb::Validator::ChannelMembership::Hidden < Accord::Validator
  def initialize(context : Kpbb::Request::ChannelMembership::Upsert)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    return unless @context.input.has_key? "hidden"
    if !@context.is_user
      errors.add(:hidden, "You can't edit another user's channel hidden.")
      return
    end
  end
end
