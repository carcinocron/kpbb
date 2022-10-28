require "get-youtube-id"

module Kpbb::Cron::RecentLink
  def self.run(minute : Time) : Nil
    unless ENV["UNFURL_API"]?
      Log.info { "undefined UNFURL_API" }
    end
    links = Kpbb::Link.fetch_recent minute
    # pp links

    links.each do |link|
      begin
        uri = URI.parse(link.url)
        domain = uri.host.try(&.downcase)
        # pp uri
        if youtube_id = Iom::GetYoutubeId.get_youtube_id link.url
          self.set_link_meta link.id, ({youtube_id: youtube_id}).to_json
        elsif !domain
          # puts ({ unknown: true })
          # pp ({:line => __LINE__, :after => "nil domain"})
          self.set_link_meta link.id, ({unknown: "nil domain"}).to_json
        elsif uri.has_non_html_file_extension?
          # pp ({:line => __LINE__, :after => "has_non_html_file_extension"})
          # definitely don't want to call unfurl on a pdf
          self.set_link_meta link.id, ({
            file_extension: uri.extension,
          }).to_json
        elsif domain
          # puts ({ eslif_domain: true })
          # get general metadata
          # Iom::Unfurl::Metadata.from_json(metadata)
          # p "unfurl: #{link.url}"
          unfurl_res = Kpbb::Unfurl.unfurl(link.url)
          # p unfurl_res
          # pp metadata
          # puts typeof metadata
          # puts typeof metadata
          if !(unfurl_res.starts_with?("{") && unfurl_res.ends_with?("}"))
            self.set_link_meta link.id, ({
              error:   true,
              err_msg: unfurl_res,
            }).to_json
          else
            # p JSON.parse(metadata).as_h.to_yaml
            metadata = Iom::Unfurl::MetadataResponse.from_json(unfurl_res).result
            # pp metadata
            # metadata = JSON.parse(metadata).as_h
            # metadata = metadata["result"]? || metadata
            if metadata
              self.set_link_meta link.id, Kpbb::Link::Meta.new(metadata).to_json
              # pp ({:line => __LINE__, :after => "valid metadata"})
            else
              self.set_link_meta link.id, ({error: true, err_msg: "nil unfurl metadata"}).to_json
              # pp ({:line => __LINE__, :after => "nil unfurl metadata"})
            end
          end
        else
          # puts ({ unknown: true })
          self.set_link_meta link.id, ({unknown: true}).to_json
          # pp ({:line => __LINE__, :after => "unknown: else"})
        end
      rescue ex
        # pp ({:line => __LINE__, :ex => ex})
        code = case event = ::Raven.capture(ex)
               when Bool
                 nil
               else
                 event.id
               end
        # pp ({:line => __LINE__, :code => code})
        self.set_link_meta link.id, ({
          error:   code || true,
          err_msg: ex.message,
        }).to_json
        # pp ({:line => __LINE__, :after => "set_link_meta_error"})
      end
    end
  end

  def self.set_link_meta(link_id : Int64, meta : String?) : Nil
    # puts meta
    query = <<-SQL
    UPDATE links
    SET meta = $1, updated_at = NOW()
    WHERE id = $2
    SQL
    Kpbb.db.exec query, args: [meta, link_id]
  end
end
