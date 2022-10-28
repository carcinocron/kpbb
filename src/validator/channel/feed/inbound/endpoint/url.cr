require "../../../../../request/channel/feed/inbound/endpoint/update"
require "../../../../../request/channel/feed/inbound/endpoint/create"

private alias HasEndpointUrl = (Kpbb::Request::Channel::Feed::Inbound::Endpoint::Create | Kpbb::Request::Channel::Feed::Inbound::Endpoint::Update)

class Kpbb::Validator::Channel::Feed::Inbound::Endpoint::Url < Accord::Validator
  def initialize(@context : HasEndpointUrl)
  end

  def call(errors : Accord::ErrorList)
    url = @context.model.url || ""
    unless url.presence
      errors.add(:url, "URL required.")
      return
    end
    unless url.starts_with? "https://"
      errors.add(:url, "URL must start with 'https://'")
    end
    if url.size > 2048
      errors.add(:url, "URL must be under 2048 characters.")
    end
  end
end
