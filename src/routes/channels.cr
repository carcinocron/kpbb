require "../request/channel/create"
require "../request/channel/update"

get "/channels" do |env|
  page = Kpbb::Channel.fetch_page(env)
  channelmemberships = Kpbb::ChannelMembership.find page, env.session.userId?

  if env.request.wants_json
    next (page.to_json do |collection|
      collection.map do |c|
        cm = channelmemberships.find { |m| m.channel_id == c.id }
        {
          :id           => c.id,
          :relative_url => c.relative_url,
          :handle       => c.handle,
          :dname        => c.dname,
          :bio          => c.bio,
          :avatar       => c.avatar,
          :banner       => c.banner,
          :public       => c.public,
          :listed       => c.listed,
          # :creator_id => c.creator_id,
          # :created_at => c.created_at.to_unix,
          :membership => cm ? {
            :banned => cm.banned,
            :hidden => cm.hidden,
            :follow => cm.follow,
          } : nil,
        }
      end
    end)
  end
  render_view "default", "channels/index"
end

get "/channels/create" do |env|
  redirect_if_not_authenticated
  render_view "default", "channels/create"
end

get "/c/:handle" do |env|
  env.redirect "/channels/#{env.params.url["handle"]}"
end

# if the user forgot the s
get "/channel/:handle" do |env|
  env.redirect "/channels/#{env.params.url["handle"]}"
end

get "/channels/:handle" do |env|
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  render_view "default", "channels/_handle/index"
end

get "/channels/:handle/edit" do |env|
  redirect_if_not_authenticated
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  halt_403 unless channelmembership && channelmembership.rank > 0
  render_view "default", "channels/_handle/edit"
end

post "/channels/:handle" do |env|
  redirect_if_not_authenticated
  channel : Kpbb::Channel = Kpbb::Channel.find_by_handle! env
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  halt_404 unless channel.public || (channelmembership && channelmembership.rank > 0)
  halt_403 unless channelmembership && channelmembership.rank > 0
  # body_params = env.request.body ? HTTP::Params.parse(env.request.body.not_nil!.to_s) : HTTP::Params.new
  data = Kpbb::Request::Channel::Update.new(channel, env.params.body)
  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data{
        "handle" => data.model.handle,
        "dname"  => data.model.dname,
        "bio"    => data.model.bio,
        "public" => one_or_zero(data.model.public).to_s,
        "listed" => one_or_zero(data.model.listed).to_s,
      }))
      redirect_back "#{data.model.relative_url}/edit"
    end
    next
  end

  data.save

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended data.model.relative_url
end

post "/channels" do |env|
  redirect_if_not_authenticated

  data = Kpbb::Request::Channel::Create.new(env.params.body, user_id: env.session.userId)

  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data{
        "handle" => data.model.handle,
        "dname"  => data.model.dname,
        "bio"    => data.model.bio,
        "public" => one_or_zero(data.model.public).to_s,
        "listed" => one_or_zero(data.model.listed).to_s,
      }))

      redirect_back "/channels/create"
    end
    next
  end

  data.save!

  if env.request.wants_json
    next ({
      :id => data.model.id,
    }.to_json)
  end
  redirect_intended data.model.relative_url
end
