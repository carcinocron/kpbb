require "../request/registeruser"
require "../request/loginuser"

alias HasPassword = (Kpbb::Request::RegisterUser | Kpbb::Request::LoginUser | Kpbb::Request::Settings::ChangePassword)

class Kpbb::Validator::Password < Accord::Validator
  def initialize(context : HasPassword)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.password.nil? || @context.password == ""
      errors.add(:password, "Password required.")
      return
    end
    size = @context.password.not_nil!.size
    if @context.password == "12345"
      errors.add(:password, "That's amazing, I've got the same combination on my luggage!")
      return
    end
    if @context.password == "hunter2"
      errors.add(:password, "\"<#{@context.handle}> *******\" thats what I see")
      return
    end
    if size < 8
      errors.add(:password, "Password must be at least 8 characters.")
      return
    end
  end
end
