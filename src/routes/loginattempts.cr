get "/loginattempts" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  page = Kpbb::Loginattempt.fetch_page(env)
  render_view "default", "loginattempts/index"
end

get "/loginattempts/create" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

get "/loginattempts/:loginattempt_id" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  loginattempt : Kpbb::Loginattempt = Kpbb::Loginattempt.find! env
  render_view "default", "loginattempts/_loginattempt_id/index"
end

get "/loginattempts/:loginattempt_id/edit" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

post "/loginattempts/:loginattempt_id" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

post "/loginattempts" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end
