struct Kpbb::Feed::Inbound::Payload::Data
  include JSON::Serializable

  property guid : String?
  property id : String? # youtube uses id instead of guid
  property title : String?
  property pub_date : String?
  property content : String?
  property content_snippet : String?
  property iso_date : String?
  property link : String?

  # property body : Hash(String, String)? { Hash(String, String).new }
  # property creator_id : Int64?

  # def initialize(
  #   @body : Hash(String, String),
  #   @creator_id : Int64
  # )
  # end
  def initialize(@guid = nil, @title = nil, @pub_date = nil, @content = nil, @content_snippet = nil, @iso_date = nil)
  end

  def to_body_h : Hash(String, String)
    # p ({:line => __LINE__, :pdata => self})
    body = Hash(String, String).new
    body["title"] = (title || "").strip
    if (url = self.link || self.guid)
      if url.starts_with?("https://")
        body["url"] = url
      else
        # if there is any exception to
        # requiring a url to start with
        # https://, it will go here
      end
    end

    unless body.has_key?("url")
      # @todo if an item does not have a URL,
      # it shall have a body_md
      # body["body_md"] = self.content_snippet || self.content
    end

    body
  end
end
