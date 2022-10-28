require "./env"
require "./logging"
require "kemal"
require "webslug"
require "php-shell-exec"
require "base62"
require "./kemal_patch"
require "./concern/**"
require "./util/model"
require "./util/model_url"
require "./util/**"
require "./orm/**"
require "./mask/**"
require "./db"
require "./s3"
require "./youtube"
require "./twitter"
require "./unfurl"
require "./thumbnail"
require "./policies/gate"
require "./session"
require "./view_context"
require "raven"
require "helmet"
require "./page"
require "./themes"
require "./channelaction"
require "./cron/index"
require "./iomcr/file/filetype"
require "./iomcr/url_abbr/url_abbr"
require "./headers"
require "./markdown"
require "./request/**"
require "./request/loginuser"
require "./view"
require "./ecr"
require "./raven/*"

Kemal.config.port = ENV["PORT"].to_i

# in the future, maybe we'll be behind nginx
# disable serving files from public
# serve_static false
# serve_static({"gzip" => false, "dir_listing" => false})
static_headers do |response, filepath, filestat|
  # 7 days
  response.headers.add("Cache-Control", "public, max-age=604800")
end

::Raven.configure do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.current_environment = ENV["KEMAL_ENV"]
end

# macro halt(env, status_code = 200, response = "")
#   {{env}}.response.status_code = {{status_code}}
#   {{env}}.response.print {{response}}
#   {{env}}.response.close
#   next
# end

macro halt_403
  if env.request.wants_json
    env.response.content_type = HEADER_APPLICATION_JSON
    halt env, status_code: 403, response: JSON_MESSAGE_FORBIDDEN
  else
    halt env, status_code: 403, response: render_view "simple", "403"
  end
end

macro halt_404
  if env.request.wants_json
    env.response.content_type = HEADER_APPLICATION_JSON
    halt env, status_code: 404, response: JSON_MESSAGE_NOT_FOUND
  else
    env.response.content_type = HEADER_TEXT_HTML
    halt env, status_code: 404, response: render_view "simple", "404"
  end
end

macro halt_405
  if env.request.wants_json
    env.response.content_type = HEADER_APPLICATION_JSON
    halt env, status_code: 405, response: JSON_MESSAGE_METHOD_NOT_ALLOWED
  else
    halt env, status_code: 405, response: render_view "simple", "405"
  end
end

macro halt_501
  if env.request.wants_json
    env.response.content_type = HEADER_APPLICATION_JSON
    halt env, status_code: 501, response: JSON_MESSAGE_NOT_IMPLEMENTED
  else
    halt env, status_code: 501, response: render_view "simple", "501"
  end
end

before_all do |env|
  if (env.request.wants_json)
    env.response.content_type = HEADER_APPLICATION_JSON
  else
    env.response.content_type = HEADER_TEXT_HTML
  end
end

require "./middleware/*"
require "./routes"

if ENV["SPOOF_CFIPCC"]?
  add_handler Kpbb::Middleware::SpoofCfIpCc.new
end
add_handler Kpbb::Middleware::NoCacheIfAuth.new
add_handler Kpbb::Middleware::HttpRequestLog.new
add_handler Helmet::DNSPrefetchControllerHandler.new
add_handler Helmet::FrameGuardHandler.new(Helmet::FrameGuardHandler::Origin::Nowhere)
add_handler Helmet::InternetExplorerNoOpenHandler.new
add_handler Helmet::NoSniffHandler.new
add_handler Helmet::StrictTransportSecurityHandler.new(7.day)
add_handler Helmet::XSSFilterHandler.new

# app no longer does anything, because it will be included by either server, watch_server, or cron
# Kemal.run
