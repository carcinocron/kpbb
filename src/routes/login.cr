require "../request/loginuser"

get "/login" do |env|
  redirect_if_not_guest
  register_uri = env.request.path_with_query.sub "/login", "/register" # preserve query variables like return_to
  render_view "simple", "login"
end

post "/login" do |env|
  redirect_if_not_guest

  data = Kpbb::Request::LoginUser.new(env)
  data.validate!

  if data.errors.any?
    data.log_attempt success: false
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data{
        "handle" => data.handle,
      }))
      redirect_back env.request.headers["referer"]? || "/login"
    end
    next
  end

  data.log_attempt success: true
  data.save

  env.session.bigint("userId", data.id.not_nil!)
  env.session.string("handle", data.handle)
  env.session.int("t", env.session.user_theme_id.to_i32)

  if env.request.wants_json
    next {:id => data.id}.to_json
  end

  redirect_intended "/home"
end
