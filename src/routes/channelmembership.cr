require "../request/channelmembership/upsert"

post "/channelmembership" do |env|
  redirect_if_not_authenticated
  halt_404 unless env.params.query["channel_id"]?.presence.to_i64_from_b62?
  channel : Kpbb::Channel = Kpbb::Channel.find! env.params.query["channel_id"].to_i64_from_b62

  data = Kpbb::Request::ChannelMembership::Upsert.new(channel, env.params.body, env)
  halt_403 unless data.is_user || data.is_mod

  data.validate!

  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(env.params.body))
      redirect_back channel.relative_url
    end
    next
  end

  data.save!
  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended channel.relative_url
end
