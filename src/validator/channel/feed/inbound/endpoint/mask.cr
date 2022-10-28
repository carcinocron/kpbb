require "../../../../../request/channel/feed/inbound/endpoint/update"
require "../../../../../request/channel/feed/inbound/endpoint/create"

private alias HasEndpointMask = (Kpbb::Request::Channel::Feed::Inbound::Endpoint::Create | Kpbb::Request::Channel::Feed::Inbound::Endpoint::Update)

class Kpbb::Validator::Channel::Feed::Inbound::Endpoint::Mask < Accord::Validator
  def initialize(@context : HasEndpointMask)
  end

  def call(errors : Accord::ErrorList)
    old_value = @context.model.mask
    if @context.input["mask"]?.try(&.strip).presence.nil?
      # default zero or unchanged
      return
    end
    unless new_value = Kpbb::Mask::Mask.parse_from_input(@context.input["mask"]?)
      errors.add(:mask, "Invalid mask.")
    end
  end
end
