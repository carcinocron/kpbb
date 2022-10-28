private ENDPOINT_WEBHOOK_HEADER = "X-Webhook-Auth"

post "/webhook/:endpoint_uuid/:path" do |env|
  whauth = env.request.headers[ENDPOINT_WEBHOOK_HEADER]?.try(&.strip).presence || env.params.body["secret"]?
  uuid = env.params.url["endpoint_uuid"]?
  path = Kpbb::Webhook::Inbound::PayloadPath.parse(env.params.url["path"]?)
  halt_404 if path.nil?
  # halt_404 if (uuid.try(&.size) || 0) != 32
  begin
    uuid = UUID.from_base62(uuid.not_nil!)
  rescue ex
    halt_404
  end
  halt_404 if whauth.nil?
  endpoint = Kpbb::Webhook::Inbound::Endpoint.find_by_uuid! uuid.not_nil!

  ::Raven.tags_context(
    endpoint_id: endpoint.id,
    endpoint_uuid: endpoint.uuid.to_s,
    endpoint_channel_id: endpoint.channel_id)

  halt_404 unless endpoint.active
  halt_404 unless endpoint.verify whauth.not_nil!

  body = Hash(String, String).new
  body["dedupe_minutes"] = (7 * 24 * 60).to_s
  env.params.body.each do |name, value|
    case name
    when "password", "password2", "current_password", "secret"
      # pass
    else
      body[name] = value
    end
  end

  payload = Kpbb::Webhook::Inbound::Payload.save!(
    endpoint_id: endpoint.id,
    cc_i16: env.request.cc_i16,
    ip: env.request.ip_address!,
    path: path.not_nil!,
    data: Kpbb::Webhook::Inbound::Payload::Data.new(body, endpoint.creator_id).to_json)

  endpoint.update_lastactive_at

  # pp ({:endpoint => endpoint, :payload => payload})

  next JSON_MESSAGE_OK
end
