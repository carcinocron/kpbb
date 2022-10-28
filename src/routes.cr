require "./routes/about"
require "./routes/channelmembership"
require "./routes/channels/webhook/inbound/endpoints"
require "./routes/channels/webhook/inbound/payloads"
require "./routes/channels/feed/inbound/endpoints"
require "./routes/channels/feed/inbound/payloads"
require "./routes/channels"
require "./routes/domains"
require "./routes/expanded/links"
require "./routes/home"
require "./routes/ipaddresses"
require "./routes/links"
require "./routes/login"
require "./routes/loginattempts"
require "./routes/logout"
require "./routes/mimes"
require "./routes/postusers"
require "./routes/posts"
require "./routes/referers"
require "./routes/register"
require "./routes/todo"
require "./routes/uploads"
require "./routes/settings/index"
require "./routes/settings/email"
require "./routes/settings/password"
require "./routes/settings/profile"
require "./routes/settings/theme"
require "./routes/tags"
require "./routes/useragents"
require "./routes/users"
require "./routes/webhook/endpoints"
require "./routes/img/*"
require "./routes/static"
require "./routes/test/ravenhandler"

require "./routes/index"

# require "device_detector"

# get "/nice" do |env|
#   useragent = DeviceDetector::Detector.new(env.request.user_agent).call
#   ({
#     :browser_name   => useragent.browser_name,
#     :client_os_name => useragent.os_name,
#   }).to_json
# end

# error 500 do |env|
#   puts env.request.headers
#   puts env.request.headers["Accept"]
#   if (env.request.headers["Content-Type"] || "").includes? "json"
#     return { "message" => "Internal Server Error" }.to_json
#   end
#   "Internal Server Error"
# end
