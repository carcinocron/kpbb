require "accord"
require "../../validator/*"

struct Kpbb::Request::Settings::UpdateTheme
  env : HTTP::Server::Context
  property id : Int64?
  property theme_id : Int16?

  def initialize(@env : HTTP::Server::Context)
    @id = @env.session.userId
    @theme_id = @env.params.body["theme_id"]?.try(&.to_i16?)
  end

  include Accord
  # include MoreAccord
  validates_with [Kpbb::Validator::Settings::ThemeId]

  def save
    unless @theme_id.nil?
      Kpbb.db.exec(UPDATE_USER_PROFILE, args: [
        @theme_id,
        @id,
      ])
    end
  end
end

private UPDATE_USER_PROFILE = <<-SQL
UPDATE users
SET theme_id = $1, updated_at = NOW()
WHERE id = $2
SQL
