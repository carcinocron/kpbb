require "accord"
require "../../validator/**"

# private CHANNEL_AVATAR_PREFIX = ENV["KPBB_IMG_API"] + "/img/1/"
private CHANNEL_AVATAR_PREFIX = "/img/1/"

module Kpbb::Request::Channel
  struct Creating
    ::Kpbb::Util::Model.handle_url_not_nil("/channels")

    property id : Int64?
    property creator_id : Int64
    property handle : String
    property dname : String
    property bio : String?
    property avatar : String
    property public : Bool
    property listed : Bool

    def initialize(body : HTTP::Params, @creator_id : Int64)
      @handle = body["handle"]? || ""
      @dname = body["dname"]?.presence || @handle
      @bio = body["bio"]? || ""
      # @avatar = "https://avatars.dicebear.com/v2/identicon/" + Random::Secure.hex(8) + ".svg" # hex 2 comes out as 4 characters
      @avatar = CHANNEL_AVATAR_PREFIX + Random::Secure.hex(2) + ".svg" # hex 2 comes out as 4 characters
      @public = body.truthy?("public")                                 # default false
      @listed = body.truthy?("listed")                                 # default false
    end
  end

  struct Create
    property model : Creating
    property input : HTTP::Params
    property user_id : Int64
    property connection : DB::Database

    def initialize(@input : HTTP::Params, @user_id : Int64, connection : DB::Connection? = nil)
      @connection = connection || Kpbb.db
      @model = Creating.new(@input, @user_id)
    end

    include Accord
    # include MoreAccord
    validates_with [
      Kpbb::Validator::Channel::Handle,
      Kpbb::Validator::Channel::DisplayName,
      Kpbb::Validator::Channel::Description,
      Kpbb::Validator::Channel::CreatedbyId,
    ]

    def save!
      @connection.transaction do |transaction|
        query = <<-SQL
          INSERT INTO channels (
            creator_id,
            handle, dname, bio, avatar,
            public, listed,
            updated_at, created_at
          ) VALUES (
            $1,
            $2, $3, $4, $5,
            $6, $7,
            NOW(), NOW())
          returning id
        SQL
        @model.id = transaction.connection.query_one(query, args: [
          @model.creator_id,
          @model.handle,
          @model.dname,
          @model.bio,
          @model.avatar,
          @model.public,
          @model.listed,
          # @model.body_md,
          # Markdown.to_html(@model.body_md.not_nil!),
        ], as: Int64)

        Kpbb::ChannelMembership.save!(
          channel_id: @model.id.not_nil!,
          user_id: @model.creator_id,
          rank: PG_SMALLINT_MAX,
          follow: true,
          connection: transaction.connection)
      end
    end
  end
end
