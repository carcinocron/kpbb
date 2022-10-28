require "uri"
require "kemal-session"
# require "kemal-session-postgres"
require "./kemal_session_postgres"
require "humanize_time"
require "./session/flash"

Kemal::Session.config do |config|
  config.timeout = 3.days # previously 1.hours
  config.cookie_name = "g"
  # todo postgres or redis session
  # config.engine = Kemal::Session::MemoryEngine.new
  config.engine = Kemal::Session::PostgresEngine.new(Kpbb.db)
  config.gc_interval = 8.minutes
  config.secret = ENV["COOKIE_SECRET"]
  config.secure = true if IS_PRODUCTION
  config.domain = ENV["COOKIE_DOMAIN"] ||= nil
  config.path = ENV["COOKIE_PATH"] ||= "/"
end

class Kemal::Session
  def pull_object?(key : String)
    value = self.object?(key)
    self.delete_object(key) unless value.nil?
    value
  end

  def userId? : Int64?
    self.bigint?("userId")
  end

  def userId : Int64
    self.bigint("userId")
  end

  def user_theme_id : Int16
    user_id = self.userId?
    if user_id
      query = <<-SQL
      SELECT theme_id FROM users WHERE id = $1
      SQL
      theme_id = Kpbb.db.query_one query, args: [user_id], as: {Int16?}
      return theme_id || 0_i16
    end
    return 0_i16
  end

  gate : Gate?

  def can : Gate
    @gate ||= Gate.new(self.userId?)
  end

  def admin? : Bool
    can.admin?
  end
end

macro redirect_if_not_authenticated
  if env.session.bigint?("userId").nil?
    halt env, status_code: 401, response: JSON_MESSAGE_UNAUTHORIZED if env.request.wants_json
    get_or_head = env.request.method == "GET" || env.request.method == "HEAD"
    if get_or_head
      env.redirect "/login?return_to="+URI.encode_path(env.request.path_with_query)
    elsif !get_or_head && env.request.headers["referer"]?
      env.redirect "/login?return_to="+URI.encode_path(URI.parse(env.request.headers["referer"]).path_with_query)
    else
      env.redirect "/login"
    end
    next env
  end
end

macro redirect_if_not_guest
  env.redirect "/home" unless env.session.userId?.nil?
end

# redirect_intended wants to respect any existing return_to
macro redirect_intended(default_path)
  return_to = get_return_to(env.request.path_with_query) || get_return_to(env.request.headers["referer"]?) || {{default_path}}
  env.redirect return_to
end

# redirect_back does not want to use return_to
macro redirect_back(default_path)
  return_to = env.request.headers["referer"]? || {{default_path}}
  env.redirect return_to
end

def get_return_to(uri : String?) : String?
  return nil if uri.nil?
  return nil if uri.blank?
  query = URI.parse(uri.not_nil!).query
  return nil if query.nil?
  return nil if query.blank?
  HTTP::Params.parse(query.not_nil!)["return_to"]?
end
