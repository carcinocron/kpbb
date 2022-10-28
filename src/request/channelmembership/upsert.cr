require "accord"
require "../../validator/**"

struct Kpbb::Request::ChannelMembership::Upsert
  # property model : Kpbb::ChannelMembership
  property channel : Kpbb::Channel
  property user : Kpbb::PolicyUser
  property auth : Kpbb::PolicyUser
  property usermembership : Kpbb::ChannelMembership?
  property authmembership : Kpbb::ChannelMembership?
  property input : HTTP::Params
  property query : String
  property columns : Array(String)
  property bindings : Array(::Kpbb::PGValue)
  property env : HTTP::Server::Context
  property is_mod : Bool
  property is_user : Bool

  def initialize(@channel : Kpbb::Channel, @input : HTTP::Params, @env : HTTP::Server::Context)
    @query = "INSERT INTO channelmemberships "
    @bindings = Array(::Kpbb::PGValue).new
    # @values = Array(String).new
    @columns = Array(String).new

    # @columns << "channel_id"
    # @columns << "user_id"
    # @values << nqm.next
    # @values << nqm.next
    channel_id : Int64 = @env.params.query["channel_id"].to_i64_from_b62
    user_id : Int64 = if @env.params.query["user_id"]? == "me"
      env.session.userId
    else
      @env.params.query["user_id"].to_i64_from_b62
    end
    @bindings << channel_id
    @bindings << user_id

    nqm = NextQuestionMark.new

    @is_user = env.session.userId == user_id
    @is_mod = env.session.can.edit? channel

    @user = Kpbb::PolicyUser.find! user_id
    @auth = Kpbb::PolicyUser.find! env.session.userId
    @usermembership = Kpbb::ChannelMembership.find? channel_id, @user.id
    @authmembership = Kpbb::ChannelMembership.find? channel_id, @auth.id

    if @is_user
      if input.has_key? "hidden"
        @columns << "hidden_at"
        hidden : Bool = input.truthy?("hidden")
        @bindings << (hidden ? Time.utc : nil)
      end
      if input.has_key? "follow"
        @columns << "follow"
        follow : Bool = input.truthy?("follow")
        @bindings << follow
      end
    end
    if @is_mod
      if input.has_key? "banned"
        @columns << "banned"
        @columns << "rank"
        banned : Bool = input.truthy?("banned")
        @bindings << banned
        @bindings << 0
      elsif input.has_key? "rank"
        @columns << "rank"
        rank : Int16 = input["rank"].to_i16
        @bindings << rank
      end
    end
    if @columns.size > 0
      @query += "(channel_id, user_id, " + @columns.join(", ") + ") "
      @query += "VALUES (#{nqm.next}, #{nqm.next}, " + @columns.map { nqm.next }.join(", ") + ")"
      @query += " ON CONFLICT (channel_id, user_id) DO UPDATE SET "
      @query += @columns.map { |c| "#{c} = excluded.#{c}" }.join(", ")
    end
  end

  include Accord
  # include MoreAccord
  validates_with [
    Kpbb::Validator::ChannelMembership::Follow,
    Kpbb::Validator::ChannelMembership::Hidden,
    Kpbb::Validator::ChannelMembership::Rank,
    Kpbb::Validator::ChannelMembership::Banned,
  ]

  def save!
    if @columns.size > 0
      Kpbb.db.exec @query, args: @bindings
    end
  end
end
