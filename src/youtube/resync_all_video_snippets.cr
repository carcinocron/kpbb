require "http"
require "json"

module Kpbb::Youtube
  def self.resync_all_video_snippets : Nil
    ytvideo_id_list = Array(String).new
    query = <<-SQL
      SELECT video_id FROM youtube_video_snippets
      ORDER BY published_at ASC;
    SQL
    Kpbb.db.query(query) do |rs|
      rs.each { ytvideo_id_list << rs.read(String) }
    end

    pp ytvideo_id_list.size
    ytvideo_id_list.each_slice(20) do |arr|
      pp arr.size
      sync_video_snippets arr
    end
    # Kpbb::Youtube.sync_video_snippets ytvideo_id_list
  end
end
