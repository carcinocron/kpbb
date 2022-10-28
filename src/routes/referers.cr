get "/referers" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  page = Kpbb::Referer.fetch_page(env)
  render_view "default", "referers/index"
end

get "/referers/create" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

get "/referers/:referer_id" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  referer : Kpbb::Referer = Kpbb::Referer.find! env
  render_view "default", "referers/_referer_id/index"
end

get "/referers/:referer_id/edit" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

post "/referers/:referer_id" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

post "/referers" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end
