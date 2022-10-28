require "../../request/settings/changepassword"

get "/settings/password" do |env|
  redirect_if_not_authenticated
  render_view "simple", "settings/password"
end

post "/settings/password" do |env|
  redirect_if_not_authenticated

  data = Kpbb::Request::Settings::ChangePassword.new(env)

  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data.new))
      redirect_back "/settings/password"
    end
    next
  end

  data.save

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "/settings/password"
end
