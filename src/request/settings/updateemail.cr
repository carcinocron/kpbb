require "accord"
require "../../validator/*"

struct Kpbb::Request::Settings::UpdateEmail
  property input : HTTP::Params
  property user_id : Int64
  property email : Kpbb::Email

  def initialize(@input : HTTP::Params, @user_id : Int64, @email : Kpbb::Email)
  end

  include Accord

  # include MoreAccord
  # validates_with [
  #   Kpbb::Validator::User::AddEmail,
  # ]

  def save
  end
end
