require "../../../../../validator/**"

module Kpbb::Request::Channel::Webhook::Inbound::Endpoint
  struct Update
    property model : Kpbb::Webhook::Inbound::Endpoint
    property channel : Kpbb::Channel
    property input : HTTP::Params
    property query : String
    property sets : Array(String)
    property bindings : Array(::Kpbb::PGValue)
    property channellogs : Array(Kpbb::DraftChannelLog)
    property channeljobs : Array(Kpbb::DraftChannelJob)

    property channelmembership : Kpbb::ChannelMembership
    property is_mod : Bool

    def initialize(@model : Kpbb::Webhook::Inbound::Endpoint, @channel : Kpbb::Channel, @env : HTTP::Server::Context)
      @input = env.params.body
      @channeljobs = Array(Kpbb::DraftChannelJob).new
      @channellogs = Array(Kpbb::DraftChannelLog).new

      # you can't be this far without a channelmembership
      @channelmembership = Kpbb::ChannelMembership.find!(@channel.id, @env.session.userId)

      # @is_mod = env.session.can.edit? @channel
      @is_mod = @channelmembership.not_nil!.rank > 0

      @query = "UPDATE webhook_inbound_endpoints SET "
      @bindings = Array(::Kpbb::PGValue).new
      @sets = Array(String).new
      # @model.title = env.params.body["title"]
      # @model.title = @input["title"] if @input.has_key? "title"
      # @model.body_md = @input["body_md"] if @input.has_key? "body_md"

      nqm = NextQuestionMark.new

      # the only available update is to deactivate
      # which is not reversible
      if @input.has_key? "active"
        if @model.active && (@input.falsey? "active")
          @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateWebhookInboundEndpointActive)
          @model.active = false
          @sets << "active = " + nqm.next
          @bindings << false
        end
      end
      if @input.has_key? "mask"
        new_mask = Kpbb::Mask::Mask.parse_from_input(@input["mask"]?.try(&.strip)) || Kpbb::Mask::Mask::None
        if @model.mask != new_mask
          @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateWebhookInboundEndpointMask)
          @model.mask = new_mask
          @sets << "mask = " + nqm.next
          @bindings << new_mask.to_db_value
        end
      end
      if @input.has_key? "default_body_yaml"
        if default_body_yaml = @input["default_body_yaml"]?.try(&.strip)
          default_body_json = YAML.parse(default_body_yaml).to_json
          if @model.default_body_s != default_body_json && default_body_json[0] == '{'
            @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateWebhookInboundEndpointDefaultBody)
            # @model.default_body = default_body_json
            @sets << "default_body = (#{nqm.next})::JSONB"
            @bindings << default_body_json
          end
        end
      end
      if @sets.size > 0
        @sets << "updated_at = NOW()"
        @query += @sets.join(", ")
        @query += " WHERE id = " + nqm.next
        @bindings << @model.id
      end
    end

    include Accord
    # include MoreAccord
    validates_with [
      Kpbb::Validator::Channel::Webhook::Inbound::Endpoint::Bio,
      Kpbb::Validator::Channel::Webhook::Inbound::Endpoint::Mask,
      Kpbb::Validator::Channel::Webhook::Inbound::Endpoint::DefaultBodyYaml,
    ]

    def save!
      Kpbb.db.transaction do |transaction|
        if @sets.size > 0
          transaction.connection.exec @query, args: @bindings
        end

        @channellogs.each do |draft_log|
          Kpbb::ChannelLog.save!(
            user_id: @env.session.userId,
            channel_id: @model.channel_id.not_nil!,
            post_id: @model.id.not_nil!,
            action: draft_log.action,
            data: draft_log.data,
            connection: transaction.connection)
        end
      end
    end
  end
end
