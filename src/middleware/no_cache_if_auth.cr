class Kpbb::Middleware::NoCacheIfAuth < Kemal::Handler
  def call(env)
    call_next env
    if (env.request.method == GET)
      env.response.headers["cache-control"] ||= DEFAULT_NOCACHE
    end
  end
end

private GET             = "GET"
private DEFAULT_NOCACHE = "private max-age=0"
