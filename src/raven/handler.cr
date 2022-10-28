def render_500(env, exception, verbosity)
  if exception.message == "Not Found" || exception.is_a? DB::NoResultsError
    env.response.status_code = 404
    if (env.request.wants_json)
      env.response.content_type = HEADER_APPLICATION_JSON
      env.response.print JSON_MESSAGE_NOT_FOUND
    else
      env.response.content_type = HEADER_TEXT_HTML
      env.response.print render_view "simple", "404"
    end
  else
    unless exception.message == "test1"
      puts "render_500 #{exception.message}"
    end
    # puts exception.backtrace
    env.response.status_code = 500
    # p exception.message
    # pp exception.backtrace
    if ENV["SENTRY_DSN"]?
      begin
        code = case event = ::Raven.capture(exception)
               when Bool
                 nil
               else
                 event.id
               end
      rescue ex2
        pp ex2
        code = nil
      end
    else
      pp exception
      exception.to_s STDOUT
    end

    message = nil
    if (env.request.wants_json)
      env.response.content_type = HEADER_APPLICATION_JSON
      env.response.print ({"code" => code}.to_json)
    else
      env.response.content_type = HEADER_TEXT_HTML
      env.response.print render_view "simple", "error"
    end
  end
end

error 404 do |env|
  if (env.request.wants_json)
    env.response.content_type = HEADER_APPLICATION_JSON
    env.response.print JSON_MESSAGE_NOT_FOUND
  else
    env.response.content_type = HEADER_TEXT_HTML
    env.response.print render_view "simple", "404"
  end
end
