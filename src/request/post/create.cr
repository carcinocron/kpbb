require "../../validator/**"

module Kpbb::Request::Post
  struct Creating
    Kpbb::Util::Model.base62_url_not_nil("/posts")
    Kpbb::Util::Model.base62_title_url_not_nil("/posts")

    property id : Int64?
    property channel_id : Int64?
    property parent_id : Int64?
    property creator_id : Int64
    property title : String?
    property tags : String?
    property url : String?
    property mask : Kpbb::Mask::Mask
    property link_id : Int64?
    property body_md : String?
    property draft : Bool
    property posted : Bool
    property ptype : Kpbb::Post::Type = Kpbb::Post::Type::None
    property discussion_url : String?

    def initialize(body : HTTP::Params, @creator_id : Int64)
      @channel_id = nil
      if body["channel_id"]?
        channel_id : Int64? = body["channel_id"].to_s.to_i64_from_b62?
        @channel_id = channel_id if channel_id && channel_id > 0
      end
      if body["parent_id"]?
        parent_id : Int64? = body["parent_id"].to_i64_from_b62?
        @parent_id = parent_id if parent_id && parent_id > 0
      end
      @title = body["title"]?.try(&.strip).presence
      @tags = body["tags"]?.try(&.strip).presence
      @url = body["url"]?.try(&.strip).presence
      @discussion_url = body["discussion_url"]?.try(&.strip).presence
      @body_md = body["body_md"]?.try(&.strip).presence
      @draft = true
      @draft = false if body.falsey?("draft")
      @posted = false
      @posted = true if body.truthy?("posted")
      if url = @url
        if url.starts_with_http_or_https?
          @link_id = Kpbb::Link.save! url: url
        end
        if (link_id = @link_id) && (discussion_url = @discussion_url)
          if discussion_url.starts_with_http_or_https? && discussion_url != url
            dl_id : Int64 = Kpbb::Link.save! url: discussion_url
            Kpbb::DiscussionLink.save! link_id: link_id, dlink_id: dl_id
          end
        end
      end
      @mask = Kpbb::Mask::Mask.parse_from_input(body["mask"]?.try(&.strip)) || Kpbb::Mask::Mask::None
      @ptype = Kpbb::Post::Type.parse_from_input(body["ptype"]?.try(&.strip)) || Kpbb::Post::Type::None
    end
  end

  struct Create
    property model : Creating
    property body : HTTP::Params
    property cc_i16 : Int16
    property ip : String?

    property channeljobs : Array(Kpbb::DraftChannelJob)
    property connection : DB::Database

    property channel : Kpbb::Channel?
    property channelmembership : Kpbb::ChannelMembership?
    property parent : Kpbb::Post?

    def initialize(
      @body : HTTP::Params,
      creator_id : Int64,
      @cc_i16 : Int16,
      @ip : String?,
      connection : DB::Connection? = nil
    )
      @connection = connection || Kpbb.db
      @model = Creating.new(body: @body, creator_id: creator_id)
      @channeljobs = Array(Kpbb::DraftChannelJob).new

      @channel = (channel_id = @body["channel_id"]?.try(&.to_i64_from_b62?)) ? Kpbb::Channel.find?(channel_id) : nil
      @channelmembership = (c = @channel) ? Kpbb::ChannelMembership.find?(c.id, creator_id) : nil
      @parent = (parent_id = @body["parent_id"]?.try(&.to_i64_from_b62?)) ? Kpbb::Post.find?(parent_id) : nil

      # @is_mod = env.session.can.edit? @model
    end

    include Accord
    # include MoreAccord
    validates_with [
      Kpbb::Validator::Post::Title,
      Kpbb::Validator::Post::Body,
      Kpbb::Validator::Post::CreatedbyId,
      Kpbb::Validator::Post::ChannelId,
      Kpbb::Validator::Post::ParentId,
      Kpbb::Validator::Post::Url,
      Kpbb::Validator::Post::SchedulePublishAt,
      Kpbb::Validator::Post::Mask,
      Kpbb::Validator::Post::PType,
    ]

    def save!
      @connection.transaction do |transaction|
        query = <<-SQL
          INSERT INTO posts (
            channel_id, parent_id, creator_id,
            title, tags, url, link_id, body_md, body_html,
            cc_i16, ip, mask, ptype, posted,
            draft, published_at,
            updated_at, created_at
          ) VALUES (
            $1, $2, $3,
            $4, $5, $6, $7, $8, $9,
            $10, $11, $12, $13, $14,
        SQL
        if @model.draft
          # setting draft, published_at
          query += "true, NULL, "
        else
          # setting draft, published_at
          query += "false, NOW(), "
        end
        # created_at, updated_at
        query += "NOW(), NOW()) returning id"

        body_html = if @model.body_md
                      Markdown.to_html(@model.body_md.not_nil!)
                    else
                      nil
                    end
        bindings = [
          @model.channel_id.not_nil!,
          @model.parent_id,
          @model.creator_id.not_nil!,
          @model.title,
          @model.tags,
          @model.url,
          @model.link_id,
          @model.body_md,
          body_html,
          @cc_i16,
          @ip,
          @model.mask.to_db_value,
          @model.ptype.to_db_value,
          @model.posted,
        ]

        @model.id = transaction.connection.query_one(query, args: bindings, as: Int64)

        Kpbb::Tag.sync!(post: @model, connection: transaction.connection) if @model.tags

        @channeljobs.each do |draft_job|
          Kpbb::ChannelJob.save!(
            user_id: @model.creator_id,
            channel_id: @model.channel_id.not_nil!,
            post_id: @model.id.not_nil!,
            action: draft_job.action,
            data: draft_job.data,
            run_at: draft_job.run_at,
            queued: draft_job.queued,
            connection: transaction.connection)
        end

        Kpbb::ChannelLog.save!(
          user_id: @model.creator_id,
          channel_id: @model.channel_id.not_nil!,
          post_id: @model.id.not_nil!,
          action: Kpbb::ChannelAction::Create,
          connection: transaction.connection)
        unless @model.draft
          Kpbb::ChannelLog.save!(
            user_id: @model.creator_id,
            channel_id: @model.channel_id.not_nil!,
            post_id: @model.id.not_nil!,
            action: Kpbb::ChannelAction::Publish,
            connection: transaction.connection)
        end
      end

      @model.id
    end
  end
end
