require "../../../../request/channel/webhook/inbound/endpoint/create"
require "../../../../request/channel/webhook/inbound/endpoint/update"

get "/channels/:handle/webhook/inbound/endpoints" do |env|
  redirect_if_not_authenticated
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  halt_403 unless channelmembership && channelmembership.rank > 0

  env.params.url["channel_id"] = channel.id.to_base62
  page = Kpbb::Webhook::Inbound::Endpoint.fetch_page(env)
  publicusers = Kpbb::PublicUser.find page.collection.map(&.creator_id)

  render_view "default", "channels/_handle/webhook/inbound/endpoints/index"
end

get "/channels/:handle/webhook/inbound/endpoints/create" do |env|
  redirect_if_not_authenticated
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  halt_403 unless channelmembership && channelmembership.rank > 0
  render_view "default", "channels/_handle/webhook/inbound/endpoints/create"
end

get "/channels/:handle/webhook/inbound/endpoints/:endpoint_id" do |env|
  redirect_if_not_authenticated
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  halt_403 unless channelmembership && channelmembership.rank > 0

  endpoint : Kpbb::Webhook::Inbound::Endpoint = Kpbb::Webhook::Inbound::Endpoint.find! env
  halt_404 unless channel.id == endpoint.channel_id
  createdby : Kpbb::PublicUser? = Kpbb::PublicUser.find? endpoint.creator_id

  if env.request.wants_json
    next ({
      :id => endpoint.id,
    }.to_json)
  end

  render_view "default", "channels/_handle/webhook/inbound/endpoints/_endpoint_id/index"
end

get "/channels/:handle/webhook/inbound/endpoints/:endpoint_id/secret" do |env|
  redirect_if_not_authenticated
  env.redirect "/channels/#{env.params.url["handle"]}/webhook/inbound/endpoints/#{env.params.url["endpoint_id"]}"
end

get "/channels/:handle/webhook/inbound/endpoints/:endpoint_id/edit" do |env|
  redirect_if_not_authenticated
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  halt_403 unless channelmembership && channelmembership.rank > 0

  endpoint : Kpbb::Webhook::Inbound::Endpoint = Kpbb::Webhook::Inbound::Endpoint.find! env
  halt_404 unless channel.id == endpoint.channel_id
  createdby : Kpbb::PublicUser? = Kpbb::PublicUser.find? endpoint.creator_id

  if env.request.wants_json
    next ({
      :id => endpoint.id,
    }.to_json)
  end

  render_view "default", "channels/_handle/webhook/inbound/endpoints/_endpoint_id/edit"
end

post "/channels/:handle/webhook/inbound/endpoints/:endpoint_id" do |env|
  redirect_if_not_authenticated
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  halt_404 unless channelmembership && channelmembership.rank > 0

  endpoint : Kpbb::Webhook::Inbound::Endpoint = Kpbb::Webhook::Inbound::Endpoint.find! env
  halt_404 unless channel.id == endpoint.channel_id

  # body_params = env.request.body ? HTTP::Params.parse(env.request.body.not_nil!.to_s) : HTTP::Params.new
  data = Kpbb::Request::Channel::Webhook::Inbound::Endpoint::Update.new(endpoint, channel, env)
  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data{
        "bio"               => data.model.bio,
        "mask"              => env.params.body["mask"]?,
        "default_body_yaml" => env.params.body["default_body_yaml"]?,
      }))
      redirect_back "#{channel.relative_url}/webhook/inbound/endpoints/#{data.model.id.to_s}"
    end
    next
  end

  data.save!

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "#{channel.relative_url}/webhook/inbound/endpoints/#{data.model.id.to_b62}"
end

post "/channels/:handle/webhook/inbound/endpoints" do |env|
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  halt_403 unless channelmembership && channelmembership.rank > 0

  data = Kpbb::Request::Channel::Webhook::Inbound::Endpoint::Create.new(env, channel_id: channel.id)

  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data{
        "bio"               => data.model.bio,
        "mask"              => env.params.body["mask"]?,
        "default_body_yaml" => env.params.body["default_body_yaml"]?,
      }))
      redirect_back "#{channel.relative_url}/webhook/inbound/endpoints/create"
    end
    next
  end

  data.save!

  if env.request.wants_json
    next ({
      :id     => data.model.id,
      :uuid   => data.model.uuid.to_base62,
      :secret => data.model.secret,
    }).to_json
  end

  render_view "simple", "channels/_handle/webhook/inbound/endpoints/_endpoint_id/secret"
end
