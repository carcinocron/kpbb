require "get-youtube-id"

# rss feeds dont have a real IP address
private RSS_IP_ADDRESS = "127.0.0.1"

module Kpbb::Cron::Feed::Inbound::Payload::Fetch
  def self.run(minute : Time) : Nil
    payloads = Kpbb::Feed::Inbound::Payload.fetch_one_per_endpoint(minute)
    # pp payloads
    endpoints = Kpbb::Feed::Inbound::Endpoint.find(payloads.map(&.endpoint_id).uniq)
    # pp ({:payloads_size => payloads.size})
    # pp ({:endpoint_id_list => endpoints.map(&.id)})

    payloads.each do |payload|
      # pp payload
      begin
        endpoint = endpoints.find { |endpoint| endpoint.id == payload.endpoint_id }.not_nil!
        set_posted(payload.endpoint_id)
        case payload.path
        when Kpbb::Feed::Inbound::PayloadPath::Posts
          body = endpoint.default_body.merge!(payload.data.not_nil!.to_body_h)
          body["channel_id"] = payload.channel_id.to_b62
          data = Kpbb::Request::Post::Create.new(
            body: HTTP::Params.from_hash(body),
            creator_id: endpoint.creator_id.not_nil!,
            cc_i16: Iom::CountryCode::Unknown,
            ip: RSS_IP_ADDRESS)
          data.validate!
          if data.errors.any?
            self.set_result payload.id, result: ({
              :errors => data.errorshashstring,
            }).to_json
          else
            data.save!
            self.set_result payload.id, ({:post_id => data.model.id}).to_json
          end
        else
          # puts ({ unknown: true })
          self.set_result payload.id, ({unknown: true}).to_json
        end
      rescue ex
        code = case event = ::Raven.capture(ex)
               when Bool
                 nil
               else
                 event.id
               end
        self.set_result payload.id, ({error: code || true}).to_json
      end
    end
  end

  def self.set_posted(endpoint_id : Int64) : Nil
    query = <<-SQL
    UPDATE feed_inbound_endpoints
    SET lastposted_at = NOW(),
      nextpost_at = NOW() + INTERVAL '2 minute'
    WHERE id = $1
    SQL
    Kpbb.db.exec query, args: [endpoint_id]
  end

  def self.set_result(payload_id : Int64, result : String?) : Nil
    # puts result
    # pp ({:result => result, :payload_id => payload_id})
    query = <<-SQL
    UPDATE feed_inbound_payloads
    SET result = $1, updated_at = NOW()
    WHERE id = $2
    SQL
    Kpbb.db.exec query, args: [result, payload_id]
  end
end
