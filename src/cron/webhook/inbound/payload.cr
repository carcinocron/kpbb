require "get-youtube-id"

module Kpbb::Cron::Webhook::Inbound::Payload
  def self.run(minute : Time) : Nil
    payloads = Kpbb::Webhook::Inbound::Payload.fetch_one_per_endpoint(minute)
    # pp payloads
    endpoints = Kpbb::Webhook::Inbound::Endpoint.find(payloads.map(&.endpoint_id).uniq)
    # pp ({:payloads_size => payloads.size})
    # pp ({:endpoint_id_list => endpoints.map(&.id)})

    payloads.each do |payload|
      # pp payload
      begin
        endpoint = endpoints.find { |endpoint| endpoint.id == payload.endpoint_id }.not_nil!
        set_posted(payload.endpoint_id)
        case payload.path
        when Kpbb::Webhook::Inbound::PayloadPath::Posts
          body = endpoint.default_body.merge!(payload.data.body)
          body["channel_id"] = payload.channel_id.to_b62
          data = Kpbb::Request::Post::Create.new(
            body: HTTP::Params.from_hash(body),
            creator_id: payload.data.creator_id.not_nil!,
            cc_i16: payload.cc_i16,
            ip: payload.ip)
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
    UPDATE webhook_inbound_endpoints
    SET lastposted_at = NOW(),
      nextpost_at = NOW() + INTERVAL '2 minute'
    WHERE id = $1
    SQL
    Kpbb.db.exec query, args: [endpoint_id]
  end

  def self.set_result(payload_id : Int64, result : String?) : Nil
    # puts result
    query = <<-SQL
    UPDATE webhook_inbound_payloads
    SET result = $1, updated_at = NOW()
    WHERE id = $2
    SQL
    Kpbb.db.exec query, args: [result, payload_id]
  end
end
