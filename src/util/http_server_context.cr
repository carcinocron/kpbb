APP_DOMAIN = ENV["APP_DOMAIN"]

class HTTP::Server::Context
  def perpage (default = 15_i16, max = 50_i16)
    if perpage = self.params.query["perpage"]?
      if perpage = perpage.to_i16?
        return perpage if perpage <= max
      end
    end
    return default
  end

  # referer is cool, but for some logs
  # internal referer isn't interesting
  def remote_referer
    referer = self.request.headers["referer"]? || ""
    return referer if referer == ""
    uri = URI.parse(referer)
    host = (uri.host || "").downcase
    return "" if host == APP_DOMAIN
    referer
  end
end
