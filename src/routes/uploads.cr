require "awscr-s3"

require "../request/upload/create"
require "../request/upload/update"

get "/uploads" do |env|
  redirect_if_not_authenticated
  page = Kpbb::Upload.fetch_page(env)

  if env.request.wants_json
    next (page.to_json do |collection|
      collection.map do |u|
        ({:id => u.id.to_b62})
      end
    end)
  end
  render_view "default", "uploads/index"
end

get "/uploads/create" do |env|
  redirect_if_not_authenticated
  render_view "default", "uploads/create"
end

get "/uploads/:upload_id" do |env|
  redirect_if_not_authenticated
  upload : Kpbb::Upload = Kpbb::Upload.find! env
  render_view "default", "uploads/_upload_id/index"
end

get "/uploads/:upload_id/edit" do |env|
  redirect_if_not_authenticated
  upload : Kpbb::Upload = Kpbb::Upload.find! env
  render_view "default", "uploads/_upload_id/edit"
end

post "/uploads/:upload_id" do |env|
  redirect_if_not_authenticated
  upload : Kpbb::Upload = Kpbb::Upload.find! env
  data = Kpbb::Request::Upload::Update.new(upload, env)
  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data{
        "status" => data.model.status.value.to_s,
      }))
      redirect_back "/uploads/" + data.model.id.to_b62 + "/edit"
    end
  end

  data.save

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "/uploads/" + data.model.id.to_b62
end

post "/uploads" do |env|
  redirect_if_not_authenticated
  data = Kpbb::Request::Upload::Create.new(env)

  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      # env.session.object("fo", FlashOld.new(FlashOld::Data{
      #   "channel_id" => data.model.channel_id.try(&.to_s) || "",
      # }))
      redirect_back "/uploads/create"
    end
    next
  end

  data.save!

  if env.request.wants_json
    next {:id => data.model.id}.to_json
  end
  redirect_intended "/uploads/" + data.model.id.not_nil!.to_b62
end
