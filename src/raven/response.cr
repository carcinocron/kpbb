require "json"

struct Kpbb::Raven::Response
  def self.from_ctx(env : HTTP::Server::Context)
    return ({
      :status       => env.response.status,
      :content_type => env.response.headers["Content-Type"]?,
    })
  end
end
