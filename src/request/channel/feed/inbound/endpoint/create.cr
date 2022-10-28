private COST = ENV["PASSWORD_COST"].to_i

module Kpbb::Request::Channel::Feed::Inbound::Endpoint
  struct Creating
    property id : Int64?
    property channel_id : Int64
    property creator_id : Int64
    property bio : String?
    property default_body : String?
    property url : String?
    property mask : Kpbb::Mask::Mask
    property lastposted_at : Time?
    property nextpost_at : Time?
    property created_at : Time?

    include ::Kpbb::Concern::HasDefaultBody

    def initialize(env : HTTP::Server::Context, @channel_id : Int64)
      @creator_id = env.session.userId
      @bio = env.params.body["bio"]?.try(&.strip)
      if default_body_yaml = env.params.body["default_body_yaml"]?.try(&.strip)
        @default_body = YAML.parse(default_body_yaml).to_json
      end
      @url = env.params.body["url"]?.try(&.strip)
      @mask = Kpbb::Mask::Mask.parse_from_input(env.params.body["mask"]?) || Kpbb::Mask::Mask::None
    end
  end

  struct Create
    property model : Creating
    property env : HTTP::Server::Context
    property input : HTTP::Params
    property channeljobs : Array(Kpbb::DraftChannelJob)

    def initialize(@env : HTTP::Server::Context, channel_id : Int64)
      @input = env.params.body
      @model = Creating.new(@env, channel_id)
      @channeljobs = Array(Kpbb::DraftChannelJob).new
    end

    include Accord
    # include MoreAccord
    validates_with [
      Kpbb::Validator::Channel::Feed::Inbound::Endpoint::Bio,
      Kpbb::Validator::Channel::Feed::Inbound::Endpoint::Url,
      Kpbb::Validator::Channel::Feed::Inbound::Endpoint::Mask,
      Kpbb::Validator::Channel::Feed::Inbound::Endpoint::DefaultBodyYaml,
    ]

    def save!
      Kpbb.db.transaction do |transaction|
        query = <<-SQL
          INSERT INTO feed_inbound_endpoints (
            creator_id, channel_id, url, mask, bio, data, default_body,
            active, frequency, lastpolled_at, nextpoll_at,
            created_at, updated_at
          ) VALUES ($1, $2, $3, $4, $5, null, $6,
            true, 0, null, NOW(),
            NOW(), NOW()
          ) returning id, created_at;
        SQL
        bindings = [
          @model.creator_id.not_nil!,
          @model.channel_id.not_nil!,
          @model.url.presence,
          @model.mask.to_db_value,
          @model.bio.presence,
          @model.default_body_s,
        ]
        @model.id, @model.created_at = transaction.connection.query_one(query, args: bindings, as: {Int64, Time})

        Kpbb::ChannelLog.save!(
          user_id: @env.session.userId,
          channel_id: @model.channel_id.not_nil!,
          action: Kpbb::ChannelAction::CreateFeedInboundEndpoint,
          data: Kpbb::ChannelLogData.new(endpoint_id: @model.id.not_nil!).to_json,
          connection: transaction.connection)
      end
      @model.id
    end
  end
end
