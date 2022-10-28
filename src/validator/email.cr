require "accord"
require "../request/registeruser"
require "../request/loginuser"

alias HasEmail = (Kpbb::Request::RegisterUser)

class Kpbb::Validator::Email < Accord::Validator
  def initialize(context : HasEmail)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.email.nil? || @context.email == ""
      # not required >;]
      # errors.add(:email, "Email required.")
      return
    end
    size = @context.email.not_nil!.size
  end
end
