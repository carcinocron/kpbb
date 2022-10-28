require "../../request/settings/updatetheme"

get "/settings" do |env|
  redirect_if_not_authenticated
  env.redirect "/settings/profile"
end
