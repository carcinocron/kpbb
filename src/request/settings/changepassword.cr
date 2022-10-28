require "crypto/bcrypt/password"
require "accord"
require "../../validator/*"

private COST = ENV["PASSWORD_COST"].to_i

struct Kpbb::Request::Settings::ChangePassword
  property user_id : Int64
  property handle : String
  property current_password : String
  property password : String
  property password2 : String?

  def initialize(env : HTTP::Server::Context)
    @user_id = env.session.userId
    @handle = env.session.string?("handle").not_nil!
    @current_password = env.params.body["current_password"]? || ""
    @password = env.params.body["password"]? || ""
    @password2 = env.params.body["password2"]?
  end

  include Accord
  # include MoreAccord
  validates_with [
    Kpbb::Validator::CurrentPassword,
    Kpbb::Validator::Password,
    Kpbb::Validator::PasswordConfirm,
  ]

  def save
    Kpbb.db.exec("CALL update_user_password($1, $2, $3)", args: [
      @user_id,
      Crypto::Bcrypt::Password.create(@current_password, cost: COST),
      -1, # @todo password strength
    ])
  end
end
