require "accord"
require "../../validator/**"

struct Kpbb::Request::Upload::Update
  property model : Kpbb::Upload
  property input : HTTP::Params
  property query : String
  property sets : Array(String)
  property bindings : Array(::Kpbb::PGValue)
  property env : HTTP::Server::Context
  property type : Iom::File::FileTypeResult?
  property file : Kemal::FileUpload?

  def initialize(@model : Kpbb::Upload, @env : HTTP::Server::Context)
    @input = env.params.body

    @query = "UPDATE uploads SET "
    @bindings = Array(::Kpbb::PGValue).new
    @sets = Array(String).new
    # @model.title = env.params.body["title"]
    # @model.title = @input["title"] if @input.has_key? "title"
    # @model.body_md = @input["body_md"] if @input.has_key? "body_md"

    nqm = NextQuestionMark.new

    # if @input.has_key? "channel_id"
    #   @model.channel_id = @input["channel_id"]
    #   @sets << "channel_id = "+nqm.next
    #   @bindings << @input["channel_id"]
    # end
    # if @input.has_key? "title"
    #   if (@input["title"].strip != @model.title)
    #     @sets << "title = " + nqm.next
    #     @bindings << @input["title"].strip
    #     @model.title = @input["title"].strip
    #     @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateTitle)
    #   end
    # end
    # if @input.has_key? "tags"
    #   if (@input["tags"].strip != @model.tags)
    #     @sets << "tags = " + nqm.next
    #     @bindings << @input["tags"].strip
    #     @model.tags = @input["tags"].strip
    #     @synctags = true
    #     @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateTags)
    #   end
    # end
    # if @input.has_key? "body_md"
    #   if @input["body_md"].strip != @model.body_md
    #     @sets << "body_md = " + nqm.next
    #     @sets << "body_html = " + nqm.next
    #     @bindings << @input["body_md"].strip
    #     @bindings << Markdown.to_html(@input["body_md"])
    #     @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateBodyMd)
    #   end
    # end
    # if @input.has_key? "url"
    #   url : String = @input["url"]
    #   if (url == @model.url || (url == "" && @model.url.nil?))
    #     # do nothing
    #   elsif (url.starts_with_http_or_https?)
    #     link_id = Kpbb::Link.save! url: url
    #     @sets << "url = " + nqm.next
    #     @sets << "link_id = " + nqm.next
    #     @bindings << url
    #     @bindings << link_id
    #     @model.url = url
    #     @model.link_id = link_id
    #     @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateUrl)
    #   else
    #     @sets << "url = NULL"
    #     @sets << "link_id = NULL"
    #     @model.url = nil
    #     @model.link_id = nil
    #     @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::UpdateUrl)
    #   end
    # end
    # if @input.has_key? "draft"
    #   if !@model.draft && (@input.truthy? "draft")
    #     @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::Unpublish)
    #     @model.draft = true
    #     @sets << "draft = #{nqm.next}"
    #     @bindings << true
    #     @sets << "published_at = NULL"
    #   elsif @model.draft && (@input.falsey? "draft")
    #     @channellogs << Kpbb::DraftChannelLog.new(action: Kpbb::ChannelAction::Publish)
    #     @model.draft = false
    #     @sets << "draft = " + nqm.next
    #     @bindings << false
    #     @sets << "published_at = NOW()"
    #   end
    # end
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
    Kpbb::Validator::Upload::File,
  ]

  def save
    Kpbb.db.transaction do |transaction|
      if @sets.size > 0
        transaction.connection.exec @query, args: @bindings
      end
    end
  end
end
