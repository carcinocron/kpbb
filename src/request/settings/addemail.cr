require "accord"
require "../../validator/*"

struct Kpbb::Request::Settings::AddEmail
  property input : HTTP::Params
  property add_email : String?
  property add_recovery : Bool
  property user_id : Int64

  def initialize(@input : HTTP::Params, @user_id : Int64)
    @add_email = @input["add_email"]?
    @add_recovery = @input.truthy?("add_recovery")
  end

  include Accord
  # include MoreAccord
  validates_with [
    Kpbb::Validator::User::AddEmail,
  ]

  def save
    if email = @add_email
      Kpbb::Email.save!(
        user_id: @user_id,
        email: email,
        recovery: @add_recovery)
    end
  end
end
