require "../request/registeruser"

get "/register" do |env|
  redirect_if_not_guest
  login_uri = env.request.path_with_query.sub "/register", "/login" # preserve query variables like return_to
  login_uri = login_uri.rstrip '?' 
  invitecode = env.params.query["invitecode"]?
  invitecode_required = Kpbb::Invitecode.required?
  render_view "simple", "register"
end

post "/register" do |env|
  redirect_if_not_guest

  data = Kpbb::Request::RegisterUser.new(env)

  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data{
        "handle" => data.handle,
        # "email" => data.email,
      }))
      redirect_back "/register"
    end
    next
  end

  data.save

  env.session.bigint("userId", data.id.not_nil!)
  env.session.string("handle", data.handle)
  env.session.int("t", env.session.user_theme_id.to_i32)

  if env.request.wants_json
    next {:id => data.id}.to_json
  end
  redirect_intended "/home"
end
