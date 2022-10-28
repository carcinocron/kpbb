get "/ipaddresses" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  page = Kpbb::Ipaddress.fetch_page(env)
  render_view "default", "ipaddresses/index"
end

get "/ipaddresses/create" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

get "/ipaddresses/:ipaddress_id" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  ipaddress : Kpbb::Ipaddress = Kpbb::Ipaddress.find! env
  render_view "default", "ipaddresses/_ipaddress_id/index"
end

get "/ipaddresses/:ipaddress_id/edit" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

post "/ipaddresses/:ipaddress_id" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end

post "/ipaddresses" do |env|
  redirect_if_not_authenticated
  halt_403 unless env.session.admin?
  halt_405
end
