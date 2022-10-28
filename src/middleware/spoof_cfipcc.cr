private SPOOF_CFIPCC = ENV["SPOOF_CFIPCC"]? || ""

# pp ({ :SPOOF_CFIPCC => SPOOF_CFIPCC })

class Kpbb::Middleware::SpoofCfIpCc < Kemal::Handler
  def call(env : HTTP::Server::Context)
    # pp env.request.headers["cf-ipcountry"]?
    # pp SPOOF_CFIPCC
    env.request.headers["cf-ipcountry"] = env.request.headers["cf-ipcountry"]? || SPOOF_CFIPCC
    # pp env.request.headers["cf-ipcountry"]?
    call_next env
  end
end
