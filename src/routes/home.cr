get "/home" do |env|
  redirect_if_not_authenticated
  render_view "default", "home"
end
