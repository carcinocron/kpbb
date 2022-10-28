# require "../request/tag/create"
require "../request/tag/update"

get "/tags" do |env|
  page = Kpbb::Tag.fetch_page(env)
  # tagmemberships = ChannelMembership.find page, env.session.userId?

  render_view "default", "tags/index"
end

get "/tags/create" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
  # redirect_if_not_authenticated
  # render_view "default", "tags/create"
end

get "/tags/:value" do |env|
  tag : Kpbb::Tag = Kpbb::Tag.find_by_value! env
  halt_404 unless tag.active || env.session.admin?
  render_view "default", "tags/_value/index"
end

get "/tags/:value/edit" do |env|
  redirect_if_not_authenticated
  tag : Kpbb::Tag = Kpbb::Tag.find_by_value! env
  halt_404 unless tag.active || env.session.admin?
  halt_403 unless env.session.admin?
  render_view "default", "tags/_value/edit"
end

post "/tags/:value" do |env|
  redirect_if_not_authenticated
  tag : Kpbb::Tag = Kpbb::Tag.find_by_value! env
  halt_404 unless tag.active || env.session.admin?
  halt_403 unless env.session.admin?
  data = Kpbb::Request::Tag::Update.new(tag, env.params.body)
  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      # env.session.object("fo", FlashOld.new(FlashOld::Data{
      #   "active"        => env.params.body["active"]?,
      # }))
      redirect_back "/tags/" + data.model.value + "/edit"
    end
  end

  data.save

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "/tags/" + data.model.value
end

# tags are created via posts
post "/tags" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end
