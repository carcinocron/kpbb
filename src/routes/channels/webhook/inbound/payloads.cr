# require "../../../../request/channel/webhook/inbound/payload/create"
require "../../../../request/channel/webhook/inbound/payload/update"

get "/channels/:handle/webhook/inbound/payloads" do |env|
  redirect_if_not_authenticated
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  halt_403 unless channelmembership && channelmembership.rank > 0

  env.params.url["channel_id"] = channel.id.to_base62
  page = Kpbb::Webhook::Inbound::Payload.fetch_page(env)
  # publicusers = Kpbb::PublicUser.find page.collection.map(&.creator_id)

  render_view "default", "channels/_handle/webhook/inbound/payloads/index"
end

# get "/channels/:handle/webhook/inbound/payloads/create" do |env|
#   redirect_if_not_authenticated
#   channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
#   channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
#   halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
#   halt_403 unless channelmembership && channelmembership.rank > 0
#   render_view "default", "channels/_handle/webhook/inbound/payloads/create"
# end

get "/channels/:handle/webhook/inbound/payloads/:payload_id" do |env|
  redirect_if_not_authenticated
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  halt_404 unless channelmembership && channelmembership.rank > 0

  payload : Kpbb::Webhook::Inbound::Payload = Kpbb::Webhook::Inbound::Payload.find! env
  endpoint : Kpbb::Webhook::Inbound::Endpoint = Kpbb::Webhook::Inbound::Endpoint.find! payload.endpoint_id
  # createdby : Kpbb::PublicUser? = Kpbb::PublicUser.find? payload.creator_id
  halt_404 unless channel.id == endpoint.channel_id

  render_view "default", "channels/_handle/webhook/inbound/payloads/_payload_id/index"
end

# get "/channels/:handle/webhook/inbound/payloads/:payload_id/edit" do |env|
#   redirect_if_not_authenticated
#   channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
#   channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
#   halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
#   halt_403 unless channelmembership && channelmembership.rank > 0

#   payload : Kpbb::Webhook::Inbound::Payload = Kpbb::Webhook::Inbound::Payload.find! env
#   createdby : Kpbb::PublicUser? = Kpbb::PublicUser.find? payload.creator_id

#   render_view "default", "channels/_handle/webhook/inbound/payloads/_payload_id/edit"
# end

post "/channels/:handle/webhook/inbound/payloads/:payload_id" do |env|
  redirect_if_not_authenticated
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  halt_404 unless channelmembership && channelmembership.rank > 0

  payload : Kpbb::Webhook::Inbound::Payload = Kpbb::Webhook::Inbound::Payload.find! env
  endpoint : Kpbb::Webhook::Inbound::Endpoint = Kpbb::Webhook::Inbound::Endpoint.find! payload.endpoint_id
  halt_404 unless channel.id == endpoint.channel_id

  # body_params = env.request.body ? HTTP::Params.parse(env.request.body.not_nil!.to_s) : HTTP::Params.new
  data = Kpbb::Request::Channel::Webhook::Inbound::Payload::Update.new(payload, channel, env)
  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      # env.session.object("fo", FlashOld.new(FlashOld::Data{
      #   "bio" => data.model.bio,
      # }))
      redirect_back "#{channel.relative_url}/webhook/inbound/payloads/#{data.model.id.to_b62}"
    end
    next
  end

  data.save!

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "#{channel.relative_url}/webhook/inbound/payloads/#{data.model.id.to_b62}"
end

# post "/channels/:handle/webhook/inbound/payloads" do |env|
#   channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
#   channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
#   halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
#   halt_403 unless channelmembership && channelmembership.rank > 0

#   data = Kpbb::Request::Channel::Webhook::Inbound::Payload::Create.new(env)

#   data.validate!
#   if data.errors.any?
#     if env.request.wants_json
#       halt env, status_code: 422, response: data.to_json
#     else
#       env.session.object("fe", FlashErrors.new(data.errorshashstring))
#       env.session.object("fo", FlashOld.new(FlashOld::Data{
#         "bio" => data.model.bio,
#       }))
#       redirect_back "#{channel.relative_url}/webhook/inbound/payloads/create"
#     end
#     next
#   end

#   data.save!

#   if env.request.wants_json
#     next ({
#       :id => data.model.id,
#       :uuid => data.model.uuid.to_s.gsub("-", ""),
#       :secret => data.model.secret,
#     }).to_json
#   end

#   render_view "simple", "channels/_handle/webhook/inbound/payloads/_payload_id/secret"
# end
