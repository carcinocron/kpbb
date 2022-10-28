require "../../../../../request/channel/feed/inbound/endpoint/update"
require "../../../../../request/channel/feed/inbound/endpoint/create"

private alias HasEndpointBio = (Kpbb::Request::Channel::Feed::Inbound::Endpoint::Create | Kpbb::Request::Channel::Feed::Inbound::Endpoint::Update)

class Kpbb::Validator::Channel::Feed::Inbound::Endpoint::Bio < Accord::Validator
  def initialize(@context : HasEndpointBio)
  end

  def call(errors : Accord::ErrorList)
    bio = @context.model.bio || ""
    # unless bio.presence
    #   errors.add(:bio, "Description required.")
    #   return
    # end
    if bio.size > 4095
      errors.add(:bio, "Description must be under 4,095 characters.")
    end
  end
end
