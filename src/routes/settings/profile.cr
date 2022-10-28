require "../../request/settings/updateprofile"

get "/settings/profile" do |env|
  redirect_if_not_authenticated
  render_view "simple", "settings/profile"
end

post "/settings/profile" do |env|
  redirect_if_not_authenticated

  data = Kpbb::Request::Settings::UpdateProfile.new(env)

  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      # env.session.object("fo", FlashOld.new(FlashOld::Data{
      #   # "handle" => data.handle,
      #   "bio" => data.bio,
      # } of String => String))
      flasholddata = FlashOld::Data.new
      flasholddata["bio"] = data.bio
      env.session.object("fo", FlashOld.new(flasholddata))
      redirect_back "/settings/profile"
    end
    next
  end

  data.save

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "/settings/profile"
end
