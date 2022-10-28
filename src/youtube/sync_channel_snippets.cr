require "http"
require "json"

module Kpbb::Youtube
  def self.sync_channel_snippets(channel_id_list : Array(String)) : Nil
    return unless channel_id_list.size > 0
    returned_id_list = Array(String).new
    bindings = Array(String).new

    body = HTTP::Params.build do |form|
      form.add "key", YOUTUBE_API_KEY
      form.add "part", "snippet"
      form.add "id", channel_id_list.join(",")
    end

    url = "/youtube/v3/channels?#{body}"
    res = client.get url, headers: HEADERS
    res.body.to_s STDOUT

    list = ChannelList.from_json res.body

    list.items.each do |channel|
      next unless channel_id = channel.id
      # pp ({ "channel" => channel })
      returned_id_list << channel_id
      bindings << channel_id
      bindings << channel.to_json
    end

    nqm = NextQuestionMark.new
    query = <<-SQL
    INSERT INTO youtube_channel_snippets (channel_id, data, updated_at)
    VALUES
    #{returned_id_list.map { |vs| "(" + nqm.next + ", " + nqm.next + "::jsonb - 'localized', NOW())" }.join(", ")}
    ON CONFLICT (channel_id) DO UPDATE
    SET data = excluded.data, updated_at = excluded.updated_at
    SQL
    # puts query
    result = Kpbb.db.exec query, args: bindings
    # pp result
    list
  end
end
