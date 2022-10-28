# require "device_detector"

class Kpbb::Middleware::HttpRequestLog < Kemal::Handler
  def call(env : HTTP::Server::Context)
    # useragent = DeviceDetector::Detector.new(env.request.user_agent).call
    ::Raven.user_context(handle: env.session.string?("handle"))
    ::Raven.tags_context(
      user_id: env.session.userId?,
      # browser_name: useragent.browser_name,
      # client_os_name: useragent.os_name,
      method: env.request.method,
      path: env.request.path,
      host: env.request.headers["Host"]?,
      cc_i16: env.request.cc_i16,
      ip: env.request.ip_address!)
    ::Raven.extra_context(
      query_string: env.request.query_params.to_h,
      headers: env.request.headers.to_h)

    elapsed_time = Time.measure { call_next(env) }

    Kpbb::Requestlog.insert(
      useragent: env.request.user_agent,
      referer: env.remote_referer,
      cc_i16: env.request.cc_i16,
      ipaddress: env.request.ip_address!,
      path_with_query: env.request.path_with_query,
      duration: elapsed_time.milliseconds,
      user_id: env.session.userId?,
    )
  end
end
