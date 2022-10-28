
module Kpbb::Youtube
  # @link https://developers.google.com/youtube/v3/getting-started#quota
  YOUTUBE_API_KEY = ENV["YOUTUBE_API_KEY"]

  HEADERS = HTTP::Headers{
    # "Authorization" => "API key #{YOUTUBE_API_KEY}",
    "Accept" => "application/json",
  }

  def self.client
    @@client ||= HTTP::Client.new("www.googleapis.com", tls: true)
  end
end

# Kpbb::Youtube.sync_video_snippets([
#   # "https://www.youtube.com/watch?v=ub82Xb1C8os",
#   # "ub82Xb1C8os",
#   # "4luycufIlNM", # CatuWay - Iceberg De Juegos De Android || Parte 2 || Resubido
# ])
# pp v = Kpbb::Youtube::VideoSnippet.find!("ub82Xb1C8os")

# Kpbb::Youtube.sync_channel_snippets([
#   v.channel_id,
# ])
# pp Kpbb::Youtube::ChannelSnippet.find?(v.channel_id)

# require "./youtube_topic_ids"

# pp items = Kpbb::Youtube.fetch_search(
#   search_query: "iceberg explained -ASMR",
#   order: "date",
#   published_before: (Time.utc - 2.hours).to_rfc3339,
#   published_after: (Time.utc + 1.day).to_rfc3339,
#   max_results: 50).not_nil!
# items.select! { |item| item.channel_title != "Taking It Easy" }
# pp items.map { |item| item.one_liner }
# pp items.size
