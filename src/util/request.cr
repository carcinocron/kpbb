module PathWithQuery
  def path_with_query
    path = self.path
    path = "/" unless self.path.size > 0
    # path = "/"
    if self.query
      path + "?" + self.query.not_nil!
    else
      path
    end
  end
end

class HTTP::Request
  include PathWithQuery

  def user_agent? : String?
    return self.headers["User-Agent"]?
  end

  def user_agent : String
    return self.headers["User-Agent"]? || ""
  end

  def user_agent! : String
    return self.headers["User-Agent"]
  end

  def wants_json : Bool
    @headers["Accept"]? == "application/json"
  end

  def origin : String
    return self.headers["Origin"]?
  end

  def origin_protocol : String
    if (self.headers["Origin"]? || "").starts_with? "http://"
      "http"
    else
      "https"
    end
  end
end

class URI
  include PathWithQuery
end
