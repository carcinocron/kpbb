require "../request/postuser/upsert"

post "/posts/:post_id/users/:user_id" do |env|
  redirect_if_not_authenticated
  post : Kpbb::Post = Kpbb::Post.find! env

  data = Kpbb::Request::PostUser::Upsert.new(post, env.params.body, env)
  halt_403 unless data.is_user

  data.validate!

  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(env.params.body))
      redirect_back "/posts/" + env.params.url["post_id"]
    end
    next
  end

  data.save!
  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended "/posts/" + env.params.url["post_id"]
end
