require "json"

struct Kpbb::Raven::User
  def self.from_ctx(env : HTTP::Server::Context)
    return ({
      :user_id => env.session.userId?,
      :handle  => env.session.string?("handle"),
    })
  end
end
