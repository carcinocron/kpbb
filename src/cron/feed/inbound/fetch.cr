require "json"

private HEADERS = HTTP::Headers{
  "Accept"       => "application/json",
  "Content-Type" => "application/json",
}

module Kpbb::Cron::Feed::Inbound::Endpoint::Fetch
  def self.run(minute : Time) : Nil
    unless ENV["FN_INBOUND_FEED"]?
      Log.info { "undefined FN_INBOUND_FEED" }
    end
    # p "line:#{__LINE__}"
    endpoints = Kpbb::Feed::Inbound::Endpoint.fetch_for_cron minute

    return unless endpoints.size > 0

    # if anything below fails, don't instantly retry
    set_polled(endpoints)

    # p "line:#{__LINE__}"
    res = HTTP::Client.post(
      url: ENV["FN_INBOUND_FEED"],
      headers: HEADERS,
      body: ({
        :endpoints => endpoints.map { |endpoint| ({:id => endpoint.id, :url => endpoint.url}) },
      }).to_json)
    # p "line:#{__LINE__}"

    results_body = ResultsBody.from_json(res.body)
    # p "line:#{__LINE__}"
    bulk_upsert_endpoint_payloads(endpoints, results_body.results)
    # p "line:#{__LINE__}"
    bulk_set_endpoint_meta(endpoints, results_body.results)
    # p "line:#{__LINE__}"
  end

  def self.set_polled(endpoints : Array(Kpbb::Feed::Inbound::Endpoint)) : Nil
    # puts result
    endpoint_id_list = endpoints.map(&.id)
    nqm = NextQuestionMark.new
    query = <<-SQL
    UPDATE feed_inbound_endpoints
    SET lastpolled_at = NOW(),
      nextpoll_at = NOW() + INTERVAL '1 hour'
    WHERE id IN (#{endpoint_id_list.map { nqm.next }.join ", "})
    SQL
    Kpbb.db.exec query, args: endpoint_id_list
  end

  def self.bulk_set_endpoint_meta(endpoints : Array(Kpbb::Feed::Inbound::Endpoint), results : Array(Payload)) : Nil
    results.each_with_index do |payload, index|
      if payload.meta.nil?
        # pass
      else
        endpoint = endpoints[index]

        nextpoll_at = if Time.utc - endpoint.created_at > 90.day
                        Time.utc + freq_to_nextpoll_hr(endpoint.frequency.to_f32).hours
                      elsif Time.utc - endpoint.created_at > 1.day
                        Time.utc + freq_to_nextpoll_hr(endpoint.frequency.to_f32 * (90 / (Time.utc - endpoint.created_at).total_days)).hours
                      else
                        Time.utc + 1.hour
                      end
        nextpoll_at = Math.max(nextpoll_at, Time.utc + 1.hour)

        # pp ({:line => __LINE__, :payload => payload, :index => index})
        # nqm = NextQuestionMark.new
        # if any value is null, then JSON concat "||" will return null
        query = <<-SQL
        UPDATE feed_inbound_endpoints
        SET data = COALESCE(data::JSONB, '{}'::JSONB) || ($1)::JSONB,
            updated_at = NOW(),
            frequency = (
              SELECT COUNT(distinct guid)
              FROM feed_inbound_payloads
              WHERE feed_inbound_payloads.endpoint_id = feed_inbound_endpoints.id
              AND feed_inbound_payloads.created_at > CURRENT_TIMESTAMP - INTERVAL '90 day'
            ),
            nextpoll_at = $2
        WHERE id = $3
        SQL
        Kpbb.db.exec query, args: [
          "{\"meta\": #{payload.meta}}",
          nextpoll_at,
          endpoint.id,
        ]
      end
    end
  end

  def self.bulk_upsert_endpoint_payloads(endpoints : Array(Kpbb::Feed::Inbound::Endpoint), results : Array(Payload)) : Nil
    results.each_with_index do |payload, index|
      items = payload.items.select { |item| !(item.guid.nil? || item.payload.nil?) }
      if items.nil?
        # pass
      elsif items.size == 0
        # pass
      else
        # pp ({:line => __LINE__, :payload => payload, :index => index})
        endpoint = endpoints[index]
        nqm = NextQuestionMark.new
        # if any value is null, then JSON concat "||" will return null
        values = Array(String).new
        bindings = Array(::Kpbb::PGValue).new
        items.each do |item|
          values << <<-SQL
          (#{nqm.next}, #{nqm.next}, #{nqm.next}, #{nqm.next},
            #{nqm.next}::JSONB, null, NOW(), NOW())
          SQL
          bindings << endpoint.channel_id
          bindings << endpoint.id
          # guid is probably standard, youtube uses id, link is last resort
          bindings << item.guid
          bindings << Kpbb::Feed::Inbound::PayloadPath::Posts.value
          bindings << item.payload
        end
        query = <<-SQL
        INSERT INTO feed_inbound_payloads (
          channel_id, endpoint_id,
          guid, path,
          data, result,
          created_at, updated_at)
        VALUES #{values.join(",")}
        ON CONFLICT (endpoint_id, guid) DO UPDATE
        SET data = COALESCE(feed_inbound_payloads.data::JSONB, '{}'::JSONB) || (excluded.data)::JSONB,
            updated_at = NOW()
        SQL
        Kpbb.db.exec query, args: bindings
      end
    end
  end

  struct Payload
    include JSON::Serializable
    property meta : String?
    property items : Array(PayloadItem)?

    def items : Array(PayloadItem)
      @items ||= Array(PayloadItem).new
    end
  end

  struct PayloadItem
    include JSON::Serializable
    property guid : String?
    property payload : String?
  end

  struct ResultsBody
    include JSON::Serializable
    property results : Array(Payload)?

    def results : Array(Payload)
      @results ||= Array(Payload).new
    end
  end

  # struct FeedEntry
  #   include JSON::Serializable
  #   property guid : String?
  #   property id : String?
  #   property title : String?
  #   property link : String?
  #   property iso_date : String?
  #   property pub_date : String?
  #   property content : String?
  #   property content_snippet : String?
  # end

  # struct FeedResult
  #   include JSON::Serializable
  #   property items : Array(FeedEntry)?

  #   def items : Array(FeedEntry)
  #     @items ||= Array(FeedEntry).new
  #   end
  # end

  def self.freq_to_nextpoll_hr(x : Float32) : Float32
    # Math.min(18, Math.max(1, x / (90 * 24 * 4)))
    # y = 18 - ((6 + x) / 90)
    # cap = Math.sqrt(2160)
    # y = (1 - ((Math.min(cap, Math.max(0, Math.sqrt(x)))) / cap)) * 18
    # pp ({:x => x, :y => y})
    # y
    return 1.0_f32 if x >= 270_f32
    return 12.0_f32 if x <= 1_f32
    x = Math.sqrt(Math.sqrt(x))
    b = Math.sqrt(Math.sqrt(270_f32))
    return 1 + (((b - x)/b) * 12)
  end
end
