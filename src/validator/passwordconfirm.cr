require "../request/registeruser"

alias HasPasswordConfirm = (Kpbb::Request::RegisterUser | Kpbb::Request::Settings::ChangePassword)

class Kpbb::Validator::PasswordConfirm < Accord::Validator
  def initialize(context : HasPasswordConfirm)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if !@context.password2.nil? && @context.password2 != @context.password
      errors.add(:password2, "Password does not match.")
      return
    end
  end
end
