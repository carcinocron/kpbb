require "uuid"

private COST = ENV["PASSWORD_COST"].to_i

module Kpbb::Request::Channel::Webhook::Inbound::Endpoint
  struct Creating
    property id : Int64?
    property channel_id : Int64
    property creator_id : Int64
    property bio : String?
    property default_body : String?
    property uuid : UUID
    property secret : String?
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
      @uuid = UUID.empty
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
      Kpbb::Validator::Channel::Webhook::Inbound::Endpoint::Bio,
      Kpbb::Validator::Channel::Webhook::Inbound::Endpoint::Mask,
      Kpbb::Validator::Channel::Webhook::Inbound::Endpoint::DefaultBodyYaml,
    ]

    def save!
      @model.secret = StaticArray(UInt32, 8).new(0).map { Iom::Base62.encode(Random.rand(0_i32..Int32::MAX).to_u32) }.join
      Kpbb.db.transaction do |transaction|
        query = <<-SQL
          INSERT INTO webhook_inbound_endpoints (
            creator_id, channel_id, uuid, secret, mask, bio, data, default_body,
            active, lastactive_at, created_at, updated_at
          ) VALUES ($1, $2,
            md5(random()::text || clock_timestamp()::text)::uuid,
            $3, $4, $5, null, $6, true, null, NOW(), NOW()
          ) returning id, uuid, created_at;
        SQL
        bindings = [
          @model.creator_id.not_nil!,
          @model.channel_id.not_nil!,
          Crypto::Bcrypt::Password.create(@model.secret.not_nil!, cost: COST).to_s,
          @model.mask.to_db_value,
          @model.bio.presence,
          @model.default_body_s,
        ]
        @model.id, uuid_s, @model.created_at = transaction.connection.query_one(query, args: bindings, as: {Int64, String, Time})

        @model.uuid = UUID.new uuid_s

        Kpbb::ChannelLog.save!(
          user_id: @env.session.userId,
          channel_id: @model.channel_id.not_nil!,
          action: Kpbb::ChannelAction::CreateWebhookInboundEndpoint,
          data: Kpbb::ChannelLogData.new(endpoint_id: @model.id.not_nil!).to_json,
          connection: transaction.connection)
      end
      @model.id
    end
  end
end
