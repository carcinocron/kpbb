require "accord"
require "../../validator/**"

struct Kpbb::Request::PostUser::Upsert
  # property model : Kpbb::PostUser
  property post : Kpbb::Post
  property user : Kpbb::PolicyUser
  property auth : Kpbb::PolicyUser
  property usermembership : Kpbb::PostUser?
  property authmembership : Kpbb::PostUser?
  property input : HTTP::Params
  property query : String
  property columns : Array(String)
  property bindings : Array(::Kpbb::PGValue)
  property env : HTTP::Server::Context
  property is_mod : Bool
  property is_user : Bool

  def initialize(@post : Kpbb::Post, @input : HTTP::Params, @env : HTTP::Server::Context)
    @query = "INSERT INTO postusers "
    @bindings = Array(::Kpbb::PGValue).new
    # @values = Array(String).new
    @columns = Array(String).new

    # @columns << "post_id"
    # @columns << "user_id"
    # @values << nqm.next
    # @values << nqm.next
    post_id : Int64 = @env.params.url["post_id"].to_i64_from_b62
    user_id : Int64 = if @env.params.url["user_id"]? == "me"
      env.session.userId
    else
      @env.params.url["user_id"].to_i64_from_b62
    end
    @bindings << post_id
    @bindings << user_id

    nqm = NextQuestionMark.new

    @is_user = env.session.userId == user_id
    @is_mod = env.session.can.edit? post

    @user = Kpbb::PolicyUser.find! user_id
    @auth = Kpbb::PolicyUser.find! env.session.userId
    @usermembership = Kpbb::PostUser.find? post_id, @user.id
    @authmembership = Kpbb::PostUser.find? post_id, @auth.id

    if @is_user
      if input.has_key? "hidden"
        @columns << "hidden_at"
        hidden : Bool = input.truthy?("hidden")
        @bindings << (hidden ? Time.utc : nil)
      end
      if input.has_key? "saved"
        @columns << "saved_at"
        saved : Bool = input.truthy?("saved")
        @bindings << (saved ? Time.utc : nil)
      end
    end
    if @columns.size > 0
      @query += "(post_id, user_id, " + @columns.join(", ") + ") "
      @query += "VALUES (#{nqm.next}, #{nqm.next}, " + @columns.map { nqm.next }.join(", ") + ")"
      @query += " ON CONFLICT (post_id, user_id) DO UPDATE SET "
      @query += @columns.map { |c| "#{c} = excluded.#{c}" }.join(", ")
    end
  end

  include Accord
  # include MoreAccord
  validates_with [
    Kpbb::Validator::PostUser::Saved,
    Kpbb::Validator::PostUser::Hidden,
  ]

  def save!
    if @columns.size > 0
      Kpbb.db.exec @query, args: @bindings
    end
  end
end
