require "json"

struct Kpbb::Raven::Request
  def self.from_ctx(env : HTTP::Server::Context)
    return ({
      :method  => env.request.method,
      :host    => env.request.host,
      :path    => env.request.path,
      :query   => env.request.query,
      :headers => env.request.headers,
      :ip      => env.request.ip_address?,
    })
  end
end
