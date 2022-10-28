# require "../request/link/create"
require "../request/link/update"

get "/links" do |env|
  page = Kpbb::Link.fetch_page(env)
  # linkmemberships = Kpbb::ChannelMembership.find page, env.session.userId?

  render_view "default", "links/index"
end

get "/links/create" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
  # redirect_if_not_authenticated
  # render_view "default", "links/create"
end

get "/links/:link_id" do |env|
  link : Kpbb::Link = Kpbb::Link.find! env
  # linkmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(link.id, env.session.userId) : nil
  redirect_if_not_authenticated unless link.active
  halt_403 unless link.active || env.session.admin?
  render_view "default", "links/_link_id/index"
end

get "/links/:link_id/edit" do |env|
  redirect_if_not_authenticated
  link : Kpbb::Link = Kpbb::Link.find! env
  # linkmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(link.id, env.session.userId) : nil
  halt_404 unless link.active || env.session.admin?
  halt_403 unless env.session.admin?
  render_view "default", "links/_link_id/edit"
end

post "/links/:link_id" do |env|
  redirect_if_not_authenticated
  link : Kpbb::Link = Kpbb::Link.find! env
  halt_404 unless link.active || env.session.admin?
  halt_403 unless env.session.admin?
  data = Kpbb::Request::Link::Update.new(link, env.params.body)
  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      # env.session.object("fo", FlashOld.new(FlashOld::Data{
      #   "active"        => env.params.body["active"]?,
      # }))
      redirect_back "/links/" + data.model.id.to_b62 + "/edit"
    end
  end

  data.save

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "/links/" + data.model.id.to_b62
end

# links are created via posts
post "/links" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end
