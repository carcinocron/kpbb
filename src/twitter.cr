module Kpbb::Twitter
  # the #! thing is for old tweet URLs
  # I think we can ignore it because it's a legacy feature
  # honestly looking for any excuse to turn down
  # the expensive twitter_ss lambda
  # only get 12,000 free per month (shared with other lambdas)
  # puppeteer requires the 2GB gcloud container
  # if someone could make chromeless tweet-2-svg lib that would
  # be excellent
  # twitter handles can literally be one character, max 15
  @@tweet_path = /\/?([a-zA-Z0-9-_]{1,15})\/status(?:es)?\/(\d+)(?:\/.*)?$/
  @@tweet_domains : Array(String) = [
    "twitter.com",
    # "mobile.twitter.com", # id prefer to rewrite URL
    # "www.twitter.com", # id prefer to rewrite URL
    # "twimg.com", # i dont think tweets are here
    # "twttr.net", # i dont think tweets are here
    # "twttr.com", # i dont think tweets are here
    # "abs.twimg.com", # i dont think tweets are here
  ]

  def self.domains : Array(String)
    @@domains
  end

  @[AlwaysInline]
  def self.tweet_url_meta(value : String) : TweetUrlMeta?
    self.tweet_url_meta ::URI.parse(value)
  end

  def self.tweet_url_meta(uri : ::URI) : TweetUrlMeta?
    return nil unless @@tweet_domains.includes? uri.host
    return nil unless uri.scheme == "https"
    if md = @@tweet_path.match uri.path
      if (handle = md[1]?) && (tweet_id = md[2]?)
        return TweetUrlMeta.new(tweet_id, handle)
      end
    end
    nil
  end

  struct TweetUrlMeta
    property tweet_id : String
    property handle : String

    def initialize(@tweet_id, @handle)
    end

    def sync_screenshot_if_dne : Nil
      raise "dont use unless you can make the lambda more stable"
      if ENV["TWITTER_SS_API"]?
        list = Kpbb::S3.client.list_objects(Kpbb::S3.bucket, max_keys = nil, prefix = "twitter/ss/tweet/#{@tweet_id}")
        # pp ({list: list})
        # pp ({listsize: list.size})
        # list.each do |resp|
        #   p resp.contents.map(&.key)
        # end
        form = HTTP::Params.build do |form|
          form.add "url", "https://twitter.com/#{@handle}/status/#{@tweet_id}"
        end
        # pp form
        res = HTTP::Client.post(
          url: ENV["TWITTER_SS_API"],
          headers: nil,
          form: form)
        # pp res.body

        if res.body.starts_with? "Error: could not handle the request"
          raise res.body
        end

        begin
          json = JSON.parse(res.body)
        rescue ex
          # puts res.body
          # puts ex.message
          raise ex
        end

        if json["message"].as_s != "Ok"
          # pp ({message: json["message"].as_s})
          raise json["message"].as_s
        end

        light_file = ::File.tempfile "light" do |file|
          file << json["lightFile"].as_s.not_nil!
        end
        dark_file = ::File.tempfile "dark" do |file|
          file << json["darkFile"].as_s.not_nil!
        end

        uploader = Awscr::S3::FileUploader.new(Kpbb::S3.client)
        uploader.upload(Kpbb::S3.bucket, "twitter/ss/tweet/#{@tweet_id}_light", light_file)
        uploader.upload(Kpbb::S3.bucket, "twitter/ss/tweet/#{@tweet_id}_dark", dark_file)

        ::File.delete light_file.path
        ::File.delete dark_file.path
      end
    end
  end
end
