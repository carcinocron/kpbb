require "../../../../../request/channel/feed/inbound/endpoint/update"
require "../../../../../request/channel/feed/inbound/endpoint/create"

private alias HasEndpointBody = (Kpbb::Request::Channel::Webhook::Inbound::Endpoint::Create | Kpbb::Request::Channel::Webhook::Inbound::Endpoint::Update)

class Kpbb::Validator::Channel::Webhook::Inbound::Endpoint::DefaultBodyYaml < Accord::Validator
  def initialize(@context : HasEndpointBody)
  end

  def call(errors : Accord::ErrorList)
    if (default_body_yaml_s = @context.input["default_body_yaml"]?.try(&.strip).presence).nil?
      # default zero or unchanged
      return
    end
    begin
      default_body_json_s = YAML.parse(default_body_yaml_s).to_json
      if default_body_json_s[0] != '{'
        errors.add(:default_body_yaml, "Invalid default body.")
      end
    rescue e : Exception
      # pp e
      errors.add(:default_body_yaml, "Invalid default body.")
    end
  end
end
