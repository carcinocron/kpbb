get "/useragents" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  page = Kpbb::Useragent.fetch_page(env)
  render_view "default", "useragents/index"
end

get "/useragents/create" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

get "/useragents/:useragent_id" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  useragent : Kpbb::Useragent = Kpbb::Useragent.find! env
  render_view "default", "useragents/_useragent_id/index"
end

get "/useragents/:useragent_id/edit" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

post "/useragents/:useragent_id" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

post "/useragents" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end
