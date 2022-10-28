require "uri"

module Iom::UrlAbbr
  def self.url_abbr(input : Nil) : String?
    nil
  end

  def self.url_abbr(input : String) : String?
    url_abbr(URI.parse(input))
  end

  def self.url_abbr(input : URI) : String?
    return nil unless (host = input.host)
    while host.starts_with?("www.")
      host = host[4..]
    end
    # pp input.path

    # here are all the special cases
    # if you really did not like one
    # you could monkeypatch this function
    # and comment some of these out
    handle_medium_dot_com "medium.com"
    handle_medium_dot_com "twitter.com"
    handle_medium_dot_com "mobile.twitter.com"
    handle_medium_dot_com "m.twitter.com"
    handle_medium_dot_com "nitter.net"
    handle_medium_dot_com "dev.to"
    handle_medium_dot_com "soundcloud.com"
    handle_medium_dot_com "anchor.fm"
    handle_medium_dot_com "twitch.tv"
    handle_medium_dot_com "tiktok.com"
    handle_medium_dot_com "instagram.com"
    handle_medium_dot_com "google.com"
    handle_medium_dot_com "facebook.com"
    handle_medium_dot_com "linkedin.com"
    handle_github_dot_com "github.com"
    handle_github_dot_com "gitlab.com"
    handle_reddit_dot_com "reddit.com"
    handle_reddit_dot_com "old.reddit.com"
    handle_reddit_dot_com "np.reddit.com"
    handle_reddit_dot_com "new.reddit.com"
    handle_imgur_dot_com "imgur.com"

    host
  end

  macro handle_medium_dot_com (domain = "medium.com")
    if host == {{domain}}
      if index = input.path.index('/', 1)
        return host + input.path[0..(index - 1)]
      end
      if input.path.size > 3
        return host + input.path
      end
    end
  end

  macro handle_github_dot_com (domain = "github.com")
    if host == {{domain}}
      if index = input.path.index('/', 1)
        if index2 = input.path.index('/', index + 1)
          return host + input.path[0..(index2 - 1)]
        end
        if index2 = input.path.index('#', index + 1)
          return host + input.path[0..(index2 - 1)]
        end
        return host + input.path.rstrip('/')
      end
      if input.path.size > 3
        return host + input.path
      end
    end
  end

  macro handle_reddit_dot_com (domain = "reddit.com")
    if host == {{domain}}
      path = input.path
      if index = path.index("/r/")
        if index2 = path.index('/', 4)
          return host + path[0..(index2 - 1)]
        end
        if index2 = path.index('#', index + 1)
          return host + path[0..(index2 - 1)]
        end
        return host + path.rstrip('/')
      end
      if input.path.index("/gallery/") == 0
        return host + "/gallery"
      end
      if path.index("/user/") == 0
        path = path.sub("/user/", "/u/")
      end
      if index = path.index("/u/")
        if index2 = path.index('/', 4)
          return host + path[0..(index2 - 1)]
        end
        if index2 = path.index('#', index + 1)
          return host + path[0..(index2 - 1)]
        end
        return host + path.rstrip('/')
      end
      return host
    end
  end

  macro handle_imgur_dot_com (domain = "imgur.com")
    if host == {{domain}}
      if input.path.index("/a/") == 0
        return host + "/a"
      end
      if input.path.index("/r/") == 0
        return host + "/r"
      end
      if input.path.index("/gallery/") == 0
        return host + "/gallery"
      end
      return host
    end
  end
end

# crystal run ./src/iomcr/url_abbr/url_abbr.cr
# [
# "https://www.github.com/username/really-cool-repo/but-wait-theres-more",
# "https://www.github.com/username/really-cool-repo#literally-garbage",
# "https://www.github.com/username/really-cool-repo",
# "https://www.github.com/username/",
# "https://www.github.com/username",
# ].each do |v|
#   p ({v, ::Iom::UrlAbbr.url_abbr(v)})
# end