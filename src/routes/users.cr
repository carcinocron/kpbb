# require "../request/user/create"
# require "../request/user/update"

get "/users" do |env|
  redirect_if_not_authenticated
  halt_404 unless env.session.admin?
  page = Kpbb::PublicUser.fetch_page(env)
  render_view "default", "users/index"
end

get "/users/create" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
  render_view "default", "users/create"
end

get "/u/:handle" do |env|
  env.redirect "/users/#{env.params.url["handle"]}"
end

# if the user forgot the s
get "/user/:handle" do |env|
  env.redirect "/users/#{env.params.url["handle"]}"
end

get "/users/:handle" do |env|
  redirect_if_not_authenticated
  user = Kpbb::PublicUser.find_by_handle! env.params.url["handle"]
  render_view "default", "users/_user_id/index"
end

get "/users/:handle/edit" do |env|
  redirect_if_not_authenticated
  halt_404 unless env.session.admin?
  halt_405
  # user = Kpbb::PublicUser.find! env
  # render_view "default", "users/_user_id/edit"
end

post "/users/:handle" do |env|
  redirect_if_not_authenticated
  # user = Kpbb::PublicUser.find! env
  halt_404 unless env.session.admin?
  halt_405
end
