struct Kpbb::Request::Post::Update
  property model : Kpbb::Post
  property body : HTTP::Params
  property query : String
  property sets : Array(String)
  property bindings : Array(::Kpbb::PGValue)
  property synctags : Bool = false
  property channellogs : Array(Kpbb::DraftChannelLog)
  property channeljobs : Array(Kpbb::DraftChannelJob)

  property channel : Kpbb::Channel?
  property channelmembership : Kpbb::ChannelMembership?
  property parent : Kpbb::Post?
  property is_mod : Bool

  def initialize(@model : Kpbb::Post, @env : HTTP::Server::Context)
    @body = env.params.body
    @channeljobs = Array(Kpbb::DraftChannelJob).new
    @channellogs = Array(Kpbb::DraftChannelLog).new

    @channel = (channel_id = @body["channel_id"]?.try(&.to_i64_from_b62?)) ? Kpbb::Channel.find?(channel_id) : nil
    @channelmembership = (c = @channel) ? Kpbb::ChannelMembership.find?(c.id, @env.session.userId) : nil
    @parent = (parent_id = @body["parent_id"]?.try(&.to_i64_from_b62?)) ? Kpbb::Post.find?(parent_id) : nil

    @is_mod = env.session.can.edit? @model

    @query = "UPDATE posts SET "
    @bindings = Array(::Kpbb::PGValue).new
    @sets = Array(String).new
    # @model.title = env.params.body["title"]
    # @model.title = @body["title"] if @body.has_key? "title"
    # @model.body_md = @body["body_md"] if @body.has_key? "body_md"

    nqm = NextQuestionMark.new

    # if @body.has_key? "channel_id"
    #   @model.channel_id = @body["channel_id"]
    #   @sets << "channel_id = "+nqm.next
    #   @bindings << @body["channel_id"]
    # end
    if @body.has_key? "title"
      new_title : String? = @body["title"]?.try(&.strip).presence
      if (new_title != @model.title)
        @sets << "title = " + nqm.next
        @bindings << new_title
        @model.title = new_title
        @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateTitle)
      end
    end
    if @body.has_key? "tags"
      new_tags : String? = @body["tags"]?.try(&.strip).presence
      if (new_tags != @model.tags)
        @sets << "tags = " + nqm.next
        @bindings << new_tags
        @model.tags = new_tags
        @synctags = true
        @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateTags)
      end
    end
    if @body.has_key? "body_md"
      new_body_md : String? = @body["body_md"]?.try(&.strip).presence
      new_body_html : String? = if new_body_md.nil?
        nil
      else
        Markdown.to_html(new_body_md.not_nil!)
      end
      if new_body_md != @model.body_md
        @sets << "body_md = " + nqm.next
        @sets << "body_html = " + nqm.next
        @bindings << new_body_md
        @bindings << new_body_html
        @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateBodyMd)
      end
    end
    if @body.has_key? "url"
      url : String? = @body["url"]?.try(&.strip).presence
      if url == @model.url
        # do nothing
      elsif (url && (url.not_nil!.starts_with_http_or_https?))
        link_id = Kpbb::Link.save! url: url.not_nil!
        @sets << "url = " + nqm.next
        @sets << "link_id = " + nqm.next
        @bindings << url
        @bindings << link_id
        @model.url = url
        @model.link_id = link_id
        @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateUrl)
      else
        @sets << "url = NULL"
        @sets << "link_id = NULL"
        @model.url = nil
        @model.link_id = nil
        @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateUrl)
      end
    end
    if @body.has_key? "draft"
      if !@model.draft && (@body.truthy? "draft")
        @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::Unpublish)
        @model.draft = true
        @sets << "draft = #{nqm.next}"
        @bindings << true
        @sets << "published_at = NULL"
      elsif @model.draft && (@body.falsey? "draft")
        @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::Publish)
        @model.draft = false
        @sets << "draft = " + nqm.next
        @bindings << false
        @sets << "published_at = NOW()"
      end
    end
    if @is_mod && @body.has_key? "locked"
      if !@model.locked && (@body.truthy? "locked")
        @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::Unlock)
        @model.locked = true
        @sets << "locked = #{nqm.next}"
        @bindings << true
      elsif @model.locked && (@body.falsey? "locked")
        @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::Lock)
        @model.locked = false
        @sets << "locked = " + nqm.next
        @bindings << false
      end
      if !@model.dead && (@body.truthy? "dead")
        @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::Undead)
        @model.dead = true
        @sets << "dead = #{nqm.next}"
        @bindings << true
      elsif @model.dead && (@body.falsey? "dead")
        @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::Dead)
        @model.dead = false
        @sets << "dead = " + nqm.next
        @bindings << false
      end
    end
    if @body.has_key? "mask"
      if new_mask = Kpbb::Mask::Mask.parse_from_input(@body["mask"]?.try(&.strip))
        if @model.mask != new_mask
          @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateMask)
          @model.mask = new_mask
          @sets << "mask = " + nqm.next
          @bindings << new_mask.to_db_value
        end
      end
    end
    if @body.has_key? "ptype"
      if new_ptype = Kpbb::Post::Type.parse_from_input(@body["ptype"]?.try(&.strip))
        if @model.ptype != new_ptype
          @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdatePostType)
          @model.ptype = new_ptype
          @sets << "ptype = " + nqm.next
          @bindings << new_ptype.to_db_value
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
    Kpbb::Validator::Post::Title,
    Kpbb::Validator::Post::Body,
    Kpbb::Validator::Post::Url,
    Kpbb::Validator::Post::SchedulePublishAt,
  ]

  def save
    Kpbb.db.transaction do |transaction|
      if @sets.size > 0
        transaction.connection.exec @query, args: @bindings
        Kpbb::Tag.sync!(post: @model, connection: transaction.connection) if @synctags
      end

      @channeljobs.each do |draft_job|
        Kpbb::ChannelJob.save!(
          user_id: @env.session.userId,
          channel_id: @model.channel_id.not_nil!,
          post_id: @model.id.not_nil!,
          action: draft_job.action,
          data: draft_job.data,
          run_at: draft_job.run_at,
          queued: draft_job.queued,
          connection: transaction.connection)
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
