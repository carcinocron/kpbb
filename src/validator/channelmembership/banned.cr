require "../../request/channelmembership/upsert"

class Kpbb::Validator::ChannelMembership::Banned < Accord::Validator
  def initialize(context : Kpbb::Request::ChannelMembership::Upsert)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    return unless @context.input.has_key? "banned"
    if !@context.is_mod
      errors.add(:banned, "You can't ban users.")
      return
    end
    if @context.is_user
      errors.add(:banned, "You can't ban yourself.")
      return
    end
    if @context.user.rank > 0 && @context.user.rank >= @context.auth.rank
      errors.add(:banned, "You can only ban lower ranked users (global rank).")
      return
    end
    if @context.usermembership && @context.usermembership.not_nil!.rank >= @context.authmembership.not_nil!.rank
      errors.add(:banned, "You can only ban lower ranked users (channel rank).")
      return
    end
  end
end
