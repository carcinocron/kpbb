require "../../request/settings/addemail"
require "../../request/settings/updateemail"

get "/settings/email" do |env|
  redirect_if_not_authenticated

  emails = Kpbb::Email.find(user_id: env.session.userId)
  render_view "simple", "settings/email"
end

post "/settings/email" do |env|
  redirect_if_not_authenticated

  data = Kpbb::Request::Settings::AddEmail.new(
    input: env.params.body,
    user_id: env.session.userId)

  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data{
        # "handle" => data.handle,
        "add_email" => data.add_email || "",
      }))
      redirect_back "/settings/email"
    end
    next
  end

  data.save

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "/settings/email"
end

post "/settings/email/:email_id" do |env|
  redirect_if_not_authenticated

  halt_404 unless email_id = env.params.url["email_id"].to_i64_from_b62?
  email : Kpbb::Email = Kpbb::Email.find!(
    email_id: email_id, user_id: env.session.userId)

  halt_404 unless email.active

  data = Kpbb::Request::Settings::UpdateEmail.new(
    input: env.params.body,
    email: email,
    user_id: env.session.userId)

  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data.new))
      flasholddata = FlashOld::Data.new
      env.session.object("fo", FlashOld.new(flasholddata))
      redirect_back "/settings/email"
    end
    next
  end

  data.save

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "/settings/email"
end
