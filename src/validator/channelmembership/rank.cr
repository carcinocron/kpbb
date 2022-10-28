require "../../request/channelmembership/upsert"

class Kpbb::Validator::ChannelMembership::Rank < Accord::Validator
  def initialize(context : Kpbb::Request::ChannelMembership::Upsert)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    return unless @context.input.has_key? "rank"
    if @context.input.has_key? "banned"
      errors.add(:rank, "Banning implies setting rank 0.")
      return
    end
    if !@context.is_mod
      errors.add(:rank, "You can't set rank on users.")
      return
    end
    if @context.is_user
      errors.add(:rank, "You can't set rank on yourself.")
      return
    end
    if @context.user.rank > 0 && @context.user.rank >= @context.auth.rank
      errors.add(:rank, "You can only set rank on lower ranked users (global rank).")
      return
    end
    if @context.usermembership && @context.usermembership.not_nil!.rank >= @context.authmembership.not_nil!.rank
      errors.add(:rank, "You can only set rank on lower ranked users (channel rank).")
      return
    end
  end
end
