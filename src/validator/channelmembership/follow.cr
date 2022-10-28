require "../../request/channelmembership/upsert"

class Kpbb::Validator::ChannelMembership::Follow < Accord::Validator
  def initialize(context : Kpbb::Request::ChannelMembership::Upsert)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    return unless @context.input.has_key? "follow"
    if !@context.is_user
      errors.add(:follow, "You can't edit another user's follow.")
      return
    end
  end
end
