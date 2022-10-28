require "get-youtube-id"

# similar to RecentLink, but must be ran after acquiring yt channel data
module Kpbb::Cron::RecentLinkAbbr::Youtube
  QUERY = <<-SQL
    WITH ytlinks AS (
      SELECT links.id AS link_id, links.meta ->> 'youtube_id' as youtube_id, 'youtube/' || (youtube_channel_snippets.data -> 'snippet' ->> 'customUrl') as new_url_abbr
      FROM links
      JOIN youtube_video_snippets ON links.meta ->> 'youtube_id' = youtube_video_snippets.video_id
      JOIN youtube_channel_snippets ON youtube_video_snippets.channel_id = youtube_channel_snippets.channel_id
      WHERE links.updated_at > (NOW() - INTERVAL '1 hour')
      AND youtube_channel_snippets.data -> 'snippet' ->> 'customUrl' IS NOT NULL
      AND links.url_abbr IS NULL
      AND links.meta ->> 'youtube_id' IS NOT NULL
    )
    UPDATE links
    SET url_abbr = (SELECT new_url_abbr FROM ytlinks WHERE ytlinks.link_id = links.id)
    WHERE links.updated_at > (NOW() - INTERVAL '1 hour')
    AND EXISTS(SELECT 1 FROM ytlinks WHERE ytlinks.link_id = links.id)
    AND links.url_abbr IS NULL
    AND links.meta ->> 'youtube_id' IS NOT NULL
    SQL

  def self.run(minute : Time) : Nil
    Kpbb.db.exec(QUERY)
  end
end
