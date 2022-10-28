require "accord"
require "../../validator/*"

struct Kpbb::Request::Settings::UpdateProfile
  env : HTTP::Server::Context
  property id : Int64?
  property bio : String?
  property pronouns : String?
  property dname : String?

  def initialize(@env : HTTP::Server::Context)
    @id = @env.session.userId
    @bio = @env.params.body["bio"]?
    @pronouns = @env.params.body["pronouns"]?
    @dname = @env.params.body["dname"]?
  end

  include Accord
  # include MoreAccord
  validates_with [
    Kpbb::Validator::User::Description,
    Kpbb::Validator::User::Pronouns,
    Kpbb::Validator::User::DisplayName,
  ]

  def save
    if @bio || @pronouns || @dname
      Kpbb.db.exec(UPDATE_USER_PROFILE, args: [
        @bio,
        @pronouns,
        @dname,
        @id,
      ])
    end
  end
end

private UPDATE_USER_PROFILE = <<-SQL
UPDATE users
SET bio = COALESCE($1, users.bio),
  pronouns = COALESCE($2, users.pronouns),
  dname = COALESCE($3, users.dname),
  updated_at = NOW()
WHERE id = $4
SQL
