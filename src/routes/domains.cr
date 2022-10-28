# require "../request/domain/create"
require "../request/domain/update"

get "/domains" do |env|
  page = Kpbb::Domain.fetch_page(env)
  # domainmemberships = ChannelMembership.find page, env.session.userId?

  render_view "default", "domains/index"
end

get "/domains/create" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
  # redirect_if_not_authenticated
  # render_view "default", "domains/create"
end

get "/domains/:domain_id" do |env|
  domain : Kpbb::Domain = Kpbb::Domain.find! env
  # domainmembership = env.session.userId? ? ChannelMembership.find?(domain.id, env.session.userId) : nil
  halt_404 unless domain.active || env.session.admin?
  render_view "default", "domains/_domain_id/index"
end

get "/domains/:domain_id/edit" do |env|
  redirect_if_not_authenticated
  domain : Kpbb::Domain = Kpbb::Domain.find! env
  # domainmembership = env.session.userId? ? ChannelMembership.find?(domain.id, env.session.userId) : nil
  halt_404 unless domain.active || env.session.admin?
  halt_403 unless env.session.admin?
  render_view "default", "domains/_domain_id/edit"
end

post "/domains/:domain_id" do |env|
  redirect_if_not_authenticated
  domain : Kpbb::Domain = Kpbb::Domain.find! env
  halt_404 unless domain.active || env.session.admin?
  halt_403 unless env.session.admin?
  data = Kpbb::Request::Domain::Update.new(domain, env.params.body)
  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      # env.session.object("fo", FlashOld.new(FlashOld::Data{
      #   "active"        => env.params.body["active"]?,
      # }))
      redirect_back "/domains/" + data.model.id.to_b62 + "/edit"
    end
  end

  data.save

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "/domains/" + data.model.id.to_b62
end

# domains are created via posts
post "/domains" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end
