require "../../request/settings/updatetheme"

get "/settings/theme" do |env|
  redirect_if_not_authenticated
  render_view "simple", "settings/theme"
end

post "/settings/theme" do |env|
  redirect_if_not_authenticated

  data = Kpbb::Request::Settings::UpdateTheme.new(env)

  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      flasholddata = FlashOld::Data.new
      unless data.theme_id.nil?
        flasholddata["theme_id"] = data.theme_id
      end
      env.session.object("fo", FlashOld.new(flasholddata))
      redirect_back "/settings/theme"
    end
    next
  end

  data.save

  unless data.theme_id.nil?
    env.session.int("t", data.theme_id.not_nil!.to_i32)
  end

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "/settings/theme"
end
