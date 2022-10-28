require "./iomcr/unfurl/unfurl"

module Kpbb::Unfurl
  def self.unfurl(url : String) : String
    form = HTTP::Params.build do |form|
      form.add "url", URI.encode_path(url)
    end
    # pp form
    res = HTTP::Client.post(
      url: ENV["UNFURL_API"],
      headers: nil,
      form: form)
    # pp res
    res.body # @todo unnest result
  end

  struct Result
    property data : JSON::Any?
  end
end
