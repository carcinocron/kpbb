def default_browser_get_headers
  HTTP::Headers{
    "Accept"           => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
    "User-Agent"       => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36",
    "CF-Connecting-IP" => "127.0.0.1",
    "Cf-Ipcountry"     => "US",
  }
end

def default_browser_post_headers
  headers = default_browser_get_headers
  headers["Content-Type"] = "application/x-www-form-urlencoded"
  headers
end

def accepts_json
  HTTP::Headers{
    "Accept" => "application/json",
  }
end
