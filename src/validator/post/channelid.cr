# require "../../request/post/update"
require "../../request/post/create"

private alias HasPostChannelId = (Kpbb::Request::Post::Create)

class Kpbb::Validator::Post::ChannelId < Accord::Validator
  def initialize(context : HasPostChannelId)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.model.channel_id.nil? || @context.model.channel_id == ""
      errors.add(:channel_id, "Channel required.")
      return
    end

    channel : PostingToChannel?
    begin
      channel = PostingToChannel.new(@context.model.channel_id.not_nil!)
    rescue ex : DB::NoResultsError
      # do nothing
    end
    if channel.nil?
      errors.add(:channel_id, "Channel does not exist.")
      return
    end

    begin
      membership = PostingToKpbb::ChannelMembership.new(
        channel.id,
        @context.model.creator_id)
    rescue ex : DB::NoResultsError
      # do nothing
    end

    if !channel.public
      if membership.nil? || membership.rank == 0
        errors.add(:channel_id, "Channel is not public.")
        return
      end
    end

    if membership && membership.banned
      errors.add(:channel_id, "Banned from channel.")
      return
    end

    # @todo reject users from making too many posts
    # @todo reject users with bad reputation from making posts
  end
end

struct PostingToChannel
  property id : Int64
  property dname : String
  property handle : String
  property public : Bool

  def initialize(channel_id : Int64)
    query = <<-SQL
    SELECT
      channels.id,
      channels.dname,
      channels.handle,
      channels.public
    FROM channels
    WHERE channels.id = $1
    LIMIT 1
    SQL
    @id, @dname, @handle, @public = Kpbb.db.query_one query,
      args: [channel_id],
      as: {
        Int64, String, String, Bool,
      }
  end
end

struct PostingToKpbb::ChannelMembership
  property id : Int64
  property rank : Int16
  property banned : Bool

  def initialize(channel_id : Int64, creator_id : Int64)
    query = <<-SQL
    SELECT
      channelmemberships.id,
      channelmemberships.rank,
      channelmemberships.banned
    FROM channelmemberships
    WHERE channelmemberships.channel_id = $1
    AND channelmemberships.user_id = $2
    LIMIT 1
    SQL
    @id, @rank, @banned = Kpbb.db.query_one(query,
      args: [channel_id, creator_id],
      as: {Int64, Int16, Bool})
  end
end
