get "/mimes" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  page = Kpbb::Mime.fetch_page(env)
  render_view "default", "mimes/index"
end

get "/mimes/create" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

get "/mimes/:mime_id" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  mime : Kpbb::Mime = Kpbb::Mime.find! env
  render_view "default", "mimes/_mime_id/index"
end

get "/mimes/:mime_id/edit" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

post "/mimes/:mime_id" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

post "/mimes" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end
