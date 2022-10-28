get "/logout" do |env|
  env.redirect "/" if env.session.bigint?("userId").nil?
  render_view "simple", "logout"
end

post "/logout" do |env|
  env.redirect "/" if env.session.bigint?("userId").nil?

  env.session.destroy

  if env.request.wants_json
    next JSON_MESSAGE_LOGGEDOUT
  end
  env.redirect "/"
end
