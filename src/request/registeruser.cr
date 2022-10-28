require "crypto/bcrypt/password"
require "accord"

private COST = ENV["PASSWORD_COST"].to_i

# private USER_AVATAR_PREFIX = ENV["KPBB_IMG_API"] + "/img/0/"
private USER_AVATAR_PREFIX = "/img/0/"

struct Kpbb::Request::RegisterUser
  property id : Int64?
  property handle : String
  property dname : String
  property password : String
  property password2 : String?
  property avatar : String
  property invitecode : String
  property email : String

  def initialize(env : HTTP::Server::Context)
    @handle = (env.params.body["handle"]? || "").rstrip
    @password = (env.params.body["password"]? || "").rstrip
    @password2 = env.params.body["password2"]?.try(&.rstrip)
    @invitecode = (env.params.body["invitecode"]? || "").rstrip
    @email = (env.params.body["email"]? || "").rstrip
    # @avatar = "https://avatars.dicebear.com/v2/jdenticon/" + Random::Secure.hex(16) + ".svg"
    @avatar = USER_AVATAR_PREFIX + Random::Secure.hex(2) + ".svg" # hex 2 comes out as 4 characters
    @dname = @handle
  end

  include Accord
  # include MoreAccord
  validates_with [
    Kpbb::Validator::Handle,
    Kpbb::Validator::Email,
    Kpbb::Validator::Password,
    Kpbb::Validator::PasswordConfirm,
    Kpbb::Validator::Invitecode,
  ]

  def save
    Kpbb.db.transaction do |tx|
      @id = tx.connection.query_one(INSERT_USER, args: [
        @handle,
        @dname,
        @avatar,
      ], as: Int64)

      tx.connection.exec("CALL update_user_password($1, $2, $3)", args: [
        @id,
        Crypto::Bcrypt::Password.create(@password, cost: COST),
        -1, # @todo password strength
      ])
      # note that @pw_id is not updated in memory, only in the DB

      unless @invitecode.nil? || @invitecode == ""
        result : DB::ExecResult = tx.connection.exec(UPDATE_INVITECODE_REDEEMER, args: [
          @id,
          @invitecode,
        ])
        if result.rows_affected != 1
          tx.rollback
          raise "Expected rows_affected=1, got #{result.rows_affected} for redeeming invite code"
        end
      end

      if @email.presence
        Kpbb::Email.save!(
          user_id: @id.not_nil!,
          email: @email,
          recovery: true,
          connection: tx.connection)
      end
    end
  end
end

private INSERT_USER = <<-SQL
INSERT INTO users (handle, dname, bio, pronouns, rank, trust, theme_id, avatar, lastlogin_at, updated_at, created_at)
VALUES ($1, $2, '', '', 0, 0, 0, $3, NOW(), NOW(), NOW())
returning id
SQL

private UPDATE_USER_PW_ID = <<-SQL
UPDATE users SET pw_id = $1 WHERE id = $2
SQL

private UPDATE_INVITECODE_REDEEMER = <<-SQL
UPDATE invitecodes SET redeemer_id = $1, redeemed_at = NOW()
WHERE code = $2 AND redeemer_id IS NULL
SQL
