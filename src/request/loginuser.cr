require "crypto/bcrypt/password"

private COST = ENV["PASSWORD_COST"].to_i

struct Kpbb::Request::LoginUser
  include Iom::CountryCode::HasCountryCodeNaturalKey

  property id : Int64?
  property handle : String
  # property email: String
  property password : String
  property cc_i16 : Int16
  property ip_address : String
  property user_agent : String

  def initialize(env : HTTP::Server::Context)
    @handle = (env.params.body["handle"]? || "").rstrip
    @password = (env.params.body["password"]? || "").rstrip
    @ip_address = env.request.ip_address!
    @user_agent = env.request.user_agent || ""
    @cc_i16 = env.request.cc_i16

    raise "IPADDRESS REQUIRED" unless @ip_address.presence
    raise "CFIPCC REQUIRED" unless @cc_i16 > 0
  end

  include Accord
  # include MoreAccord
  validates_with [
    Kpbb::Validator::Handle,
    Kpbb::Validator::Password,
  ]

  def validate
    return if errors.any?
    # the original value of handle might not be the same case as what's in the database
    @id, @handle, hashed_password = Kpbb.db.query_one(FIND_USER, @handle.downcase, as: {Int64, String, String?})

    # scenario: user does not have a password.
    # We don't want to reveal that specific detail
    # We also don't want them to succeed with a login attempt
    if hashed_password.nil? || hashed_password == ""
      errors.add(:password, BAD_PASSWORD)
      return
    end

    hashed_password = Crypto::Bcrypt::Password.new(hashed_password)

    if !(hashed_password.verify password)
      errors.add(:password, BAD_PASSWORD)
    end
  end

  def save
    Kpbb.db.exec(UPDATE_LASTLOGINAT, @id)
  end

  def log_attempt(success : Bool)
    Kpbb.db.exec(INSERT_LOGINATTEMPT, args: [
      @user_agent,
      @ip_address.presence,
      @handle,
      success,
      @cc_i16,
    ])
  end
end

private BAD_PASSWORD = "Password did not match."

private FIND_USER = <<-SQL
SELECT users.id, users.handle, passwords.hash as password
FROM users
LEFT JOIN passwords ON users.pw_id = passwords.id
WHERE lower(handle) = $1
SQL

private UPDATE_LASTLOGINAT = "UPDATE users
SET lastlogin_at = NOW()
WHERE id = $1"

private INSERT_LOGINATTEMPT = <<-SQL
WITH
  useragents AS (
    INSERT INTO useragents (value, lastseen_at, created_at) VALUES ($1, NOW(), NOW())
    ON CONFLICT (value) DO UPDATE SET lastseen_at = excluded.lastseen_at
    RETURNING id as ua_id
  )
INSERT INTO loginattempts
(handle, success, cc_i16, ip, ua_id, created_at)
SELECT $3, $4, $5, $2::INET, useragents.ua_id, NOW()
FROM useragents;
SQL
