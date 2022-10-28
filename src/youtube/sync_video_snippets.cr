require "http"
require "json"

module Kpbb::Youtube
  def self.sync_video_snippets(video_id_list : Array(String)) : Nil
    return unless video_id_list.size > 0
    returned_id_list = Array(String).new
    bindings = Array(String).new
    # client = HTTP::Client.new("www.googleapis.com", tls: true)

    body = HTTP::Params.build do |form|
      form.add "key", YOUTUBE_API_KEY
      form.add "part", "snippet,topicDetails,contentDetails"
      form.add "id", video_id_list.join(",")
    end

    url = "/youtube/v3/videos?#{body}"
    res = client.get url, headers: HEADERS

    list = VideoList.from_json res.body
    # pp list.items.size
    # res.body.to_s(STDOUT)
    list.items.each do |video|
      next unless video_id = video.id
      # # pp ({:video => video})
      returned_id_list << video_id
      bindings << video_id
      bindings << video.to_json
    end
    # end

    return nil unless returned_id_list.size > 0

    nqm = NextQuestionMark.new
    query = <<-SQL
    INSERT INTO youtube_video_snippets (video_id, data, updated_at)
    VALUES
    #{returned_id_list.map { |vs| "(" + nqm.next + ", " + nqm.next + "::jsonb - 'localized', NOW())" }.join(", ")}
    ON CONFLICT (video_id) DO UPDATE
    SET data = excluded.data, updated_at = excluded.updated_at
    SQL

    result = Kpbb.db.exec query, args: bindings
    if result.rows_affected > 0
      # we'll manually set published_at
      # because the generated column syntax
      # thinks this is "mutable" because of the timezone
      nqm = NextQuestionMark.new
      query = <<-SQL
      UPDATE youtube_video_snippets
      SET published_at = ((data -> 'snippet' -> 'publishedAt')::TEXT)::TIMESTAMPTZ AT TIME ZONE 'UTC'
      WHERE youtube_video_snippets.video_id IN (#{returned_id_list.map { nqm.next }.join(", ")})
      SQL
      result = Kpbb.db.exec query, args: returned_id_list
    end
  end
end
