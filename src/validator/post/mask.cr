# require "../../request/post/update"
require "../../request/post/create"

private alias HasPostMask = (Kpbb::Request::Post::Create | Kpbb::Request::Post::Update)

class Kpbb::Validator::Post::Mask < Accord::Validator
  def initialize(context : HasPostMask)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    mask : Kpbb::Mask::Mask = @context.model.mask
    if mask == Kpbb::Mask::Mask::None
      return
    end

    unless channel_id = @context.model.channel_id
      return
    end
    unless creator_id = @context.model.creator_id
      return
    end

    # channel mask
    if mask == Kpbb::Mask::Mask::Channel || mask == Kpbb::Mask::Mask::ChannelModerator
      if @context.channel && (membership = @context.channelmembership) && membership.rank == 0
        errors.add(:mask, "Not authorized to use selected mask.")
        return
      end
    end

    # @todo more masks
  end
end
